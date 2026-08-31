import type { QueryClient } from "@tanstack/react-query";
import { webConfig } from "./config";
import { groupQueryKeys } from "./query-client";

export interface WebSocketLike {
  onmessage: ((event: MessageEvent<string>) => void) | null;
  onerror: ((event: Event) => void) | null;
  onclose: ((event: CloseEvent) => void) | null;
  close: () => void;
}

export interface GroupWebSocketOptions {
  groupId: string;
  queryClient: QueryClient;
  baseUrl?: string;
  webSocketFactory?: (url: string) => WebSocketLike;
}

export interface GroupWebSocketConnection {
  close: () => void;
}

function websocketUrl(groupId: string, baseUrl: string): string {
  const origin = baseUrl
    ? baseUrl.replace(/^http:/, "ws:").replace(/^https:/, "wss:")
    : (globalThis.location?.origin
        .replace(/^http:/, "ws:")
        .replace(/^https:/, "wss:") ?? "");
  return `${origin.replace(/\/+$/, "")}/api/v1/groups/${encodeURIComponent(groupId)}/events`;
}

function isDataChangedMessage(event: MessageEvent<string>): boolean {
  try {
    const message = JSON.parse(event.data) as { type?: unknown };
    return (
      message !== null &&
      typeof message === "object" &&
      message.type === "data_changed"
    );
  } catch {
    return false;
  }
}

export function connectGroupWebSocket({
  groupId,
  queryClient,
  baseUrl = webConfig.apiBaseUrl,
  webSocketFactory,
}: GroupWebSocketOptions): GroupWebSocketConnection {
  if (typeof globalThis.WebSocket === "undefined" && !webSocketFactory) {
    return { close: () => undefined };
  }

  const factory: (url: string) => WebSocketLike =
    webSocketFactory ?? ((url: string) => new globalThis.WebSocket(url));
  const socket = factory(websocketUrl(groupId, baseUrl));
  socket.onmessage = (event) => {
    if (!isDataChangedMessage(event)) return;
    const keys = Object.values(groupQueryKeys(groupId));
    void Promise.all(
      keys.map((queryKey) => queryClient.invalidateQueries({ queryKey })),
    );
  };
  socket.onerror = () => undefined;
  socket.onclose = () => undefined;

  return {
    close: () => {
      socket.onmessage = null;
      socket.onerror = null;
      socket.onclose = null;
      socket.close();
    },
  };
}

export const createGroupWebSocket = connectGroupWebSocket;

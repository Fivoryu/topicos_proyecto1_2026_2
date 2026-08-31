import { QueryClient } from "@tanstack/react-query";
import { describe, expect, it, vi } from "vitest";

import {
  connectGroupWebSocket,
  type WebSocketLike,
} from "../../src/core/websocket";
import { groupQueryKeys } from "../../src/core/query-client";

class FakeWebSocket implements WebSocketLike {
  static instances: FakeWebSocket[] = [];
  readonly url: string;
  onmessage: ((event: MessageEvent<string>) => void) | null = null;
  onerror: (() => void) | null = null;
  onclose: (() => void) | null = null;
  close = vi.fn();

  constructor(url: string) {
    this.url = url;
    FakeWebSocket.instances.push(this);
  }

  receive(payload: unknown) {
    this.onmessage?.({ data: JSON.stringify(payload) } as MessageEvent<string>);
  }
}

describe("group websocket", () => {
  it("invalidates every group query from the signal without reading monetary or role data", () => {
    FakeWebSocket.instances = [];
    const queryClient = new QueryClient();
    const invalidateQueries = vi
      .spyOn(queryClient, "invalidateQueries")
      .mockResolvedValue(undefined);

    connectGroupWebSocket({
      groupId: "group-demo",
      queryClient,
      webSocketFactory: (url) => new FakeWebSocket(url),
    });
    const socket = FakeWebSocket.instances[0];
    socket.receive({
      type: "data_changed",
      balanceCents: 999999,
      role: "owner",
    });

    expect(invalidateQueries).toHaveBeenCalledTimes(5);
    expect(
      invalidateQueries.mock.calls.map(([options]) => options?.queryKey),
    ).toEqual(Object.values(groupQueryKeys("group-demo")));
  });

  it("closes cleanly when REST remains the authoritative path during an outage", () => {
    FakeWebSocket.instances = [];
    const queryClient = new QueryClient();
    const connection = connectGroupWebSocket({
      groupId: "group-demo",
      queryClient,
      webSocketFactory: (url) => new FakeWebSocket(url),
    });
    const socket = FakeWebSocket.instances[0];

    connection.close();

    expect(socket.close).toHaveBeenCalledTimes(1);
  });
});

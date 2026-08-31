"""In-process group invalidation broadcaster.

The event channel deliberately carries no domain data.  A successful mutation
publishes a small signal and clients refetch the authoritative REST resources.
"""

from __future__ import annotations

import asyncio
from collections import defaultdict
from typing import Any


class _Subscription:
    """An async subscription whose wake-up is safe across event-loop threads."""

    def __init__(self) -> None:
        self._loop = asyncio.get_running_loop()
        self._queue: asyncio.Queue[dict[str, str]] = asyncio.Queue()

    def put_nowait(self, frame: dict[str, str]) -> None:
        """Schedule a frame on the subscriber's event loop."""

        self._loop.call_soon_threadsafe(self._queue.put_nowait, frame)

    async def get(self) -> dict[str, str]:
        """Wait for the next invalidation frame."""

        return await self._queue.get()


class GroupEventBroadcaster:
    """Publish invalidation-only events to subscribers grouped by group id."""

    FRAME: tuple[tuple[str, str], ...] = (("type", "data_changed"),)

    def __init__(self) -> None:
        self._subscribers: defaultdict[object, set[Any]] = defaultdict(set)

    def subscribe(self, group_id: object) -> _Subscription:
        """Register and return a subscription for one group."""

        subscription = _Subscription()
        self._subscribers[group_id].add(subscription)
        return subscription

    def unsubscribe(self, group_id: object, subscription: object) -> None:
        """Remove a disconnected subscription without affecting other clients."""

        subscribers = self._subscribers.get(group_id)
        if subscribers is None:
            return
        subscribers.discard(subscription)
        if not subscribers:
            self._subscribers.pop(group_id, None)

    def publish(self, group_id: object) -> None:
        """Best-effort publish; notification failure never reaches the mutation."""

        frame = dict(self.FRAME)
        for subscriber in tuple(self._subscribers.get(group_id, ())):
            try:
                subscriber.put_nowait(frame)
            except Exception:
                # A closed socket or event loop is a stale notification endpoint,
                # not a failed source-data transaction.
                self._subscribers.get(group_id, set()).discard(subscriber)


__all__ = ["GroupEventBroadcaster"]

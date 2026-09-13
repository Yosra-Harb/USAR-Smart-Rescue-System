import {
  useCallback,
  useEffect,
  useState,
} from "react";

import type { MissionDataSource } from "../data/missionDataSource";
import type { MissionSnapshot } from "../types/mission";

type MissionSnapshotState = {
  snapshot: MissionSnapshot | null;
  error: string | null;
  isLoading: boolean;
  reload: () => void;
};

type UseMissionSnapshotOptions = {
  pollingIntervalMs?: number;
};

export function useMissionSnapshot(
  dataSource: MissionDataSource,
  options: UseMissionSnapshotOptions = {},
): MissionSnapshotState {
  const { pollingIntervalMs } = options;

  const [snapshot, setSnapshot] =
    useState<MissionSnapshot | null>(null);

  const [error, setError] =
    useState<string | null>(null);

  const [isLoading, setIsLoading] =
    useState(true);

  const [reloadToken, setReloadToken] =
    useState(0);

  const reload = useCallback(() => {
    setReloadToken((current) => current + 1);
  }, []);

  useEffect(() => {
    let isCancelled = false;
    let pollingTimer: number | undefined;

    async function loadMission(): Promise<void> {
      setIsLoading(true);
      setError(null);

      try {
        const nextSnapshot =
          await dataSource.loadSnapshot();

        if (isCancelled) {
          return;
        }

        setSnapshot(nextSnapshot);
      } catch (loadError: unknown) {
        if (isCancelled) {
          return;
        }

        const message =
          loadError instanceof Error
            ? loadError.message
            : "Unknown mission data error.";

        setError(message);
      } finally {
        if (!isCancelled) {
          setIsLoading(false);

          if (
            pollingIntervalMs !== undefined &&
            pollingIntervalMs > 0
          ) {
            pollingTimer = window.setTimeout(
              () => {
                void loadMission();
              },
              pollingIntervalMs,
            );
          }
        }
      }
    }

    void loadMission();

    return () => {
      isCancelled = true;

      if (pollingTimer !== undefined) {
        window.clearTimeout(pollingTimer);
      }
    };
  }, [
    dataSource,
    pollingIntervalMs,
    reloadToken,
  ]);

  return {
    snapshot,
    error,
    isLoading,
    reload,
  };
}
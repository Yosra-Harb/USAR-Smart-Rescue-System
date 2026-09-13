/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_MISSION_DATA_SOURCE?:
    | "mock"
    | "api";

  readonly VITE_MISSION_SNAPSHOT_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
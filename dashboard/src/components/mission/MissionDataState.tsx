type MissionDataStateVariant =
  | "loading"
  | "error"
  | "empty";

type MissionDataStateProps = {
  variant: MissionDataStateVariant;
  title: string;
  message: string;
  onRetry?: () => void;
};

export default function MissionDataState({
  variant,
  title,
  message,
  onRetry,
}: MissionDataStateProps) {
  const isError = variant === "error";

  return (
    <main className="mission-workspace mission-workspace--state">
      <section
        className={`mission-data-state mission-data-state--${variant}`}
        role={isError ? "alert" : "status"}
        aria-live={isError ? "assertive" : "polite"}
        aria-busy={variant === "loading"}
      >
        {variant === "loading" ? (
          <span
            className="mission-data-state__spinner"
            aria-hidden="true"
          />
        ) : (
          <span
            className="mission-data-state__symbol"
            aria-hidden="true"
          >
            {isError ? "!" : "—"}
          </span>
        )}

        <h2>{title}</h2>

        <p>{message}</p>

        {isError && onRetry ? (
          <button
            type="button"
            className="mission-data-state__action"
            onClick={onRetry}
          >
            Retry
          </button>
        ) : null}
      </section>
    </main>
  );
}

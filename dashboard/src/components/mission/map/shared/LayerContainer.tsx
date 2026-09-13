import type { ReactNode } from "react";

type LayerContainerProps = {
  children: ReactNode;
  zIndex: number;
  visible?: boolean;
  interactive?: boolean;
};

export default function LayerContainer({
  children,
  zIndex,
  visible = true,
  interactive = false,
}: LayerContainerProps) {
  if (!visible) {
    return null;
  }

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        zIndex,
        pointerEvents: interactive ? "auto" : "none",
      }}
    >
      {children}
    </div>
  );
}
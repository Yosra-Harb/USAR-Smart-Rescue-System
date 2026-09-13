/**
 * Position inside the MATLAB mission grid.
 * Coordinates use the dashboard XY convention exported by the integration contract:
 * x = MATLAB column, y = MATLAB row.
 * A physical meter scale must be defined separately before converting grid length to meters.
 */
export interface Position {
  /** Horizontal grid coordinate (MATLAB column). */
  x: number;

  /** Vertical grid coordinate (MATLAB row). */
  y: number;
}

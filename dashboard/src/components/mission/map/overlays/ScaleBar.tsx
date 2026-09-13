export default function ScaleBar() {
  return (
    <div className="scale-bar">
      <div className="scale-line">
        <div className="scale-segment dark" />
        <div className="scale-segment light" />
      </div>
      <div className="scale-labels">
        <span>0</span>
        <span>10 cells</span>
      </div>
    </div>
  );
}

const labels = ["0", "10", "20", "30", "40", "50"];

export default function GridLabels() {
  return (
    <>
      <div className="grid-labels-top">
        {labels.map((label) => <span key={label}>{label}</span>)}
      </div>
      <div className="grid-labels-left">
        {[...labels].reverse().map((label) => <span key={label}>{label}</span>)}
      </div>
    </>
  );
}

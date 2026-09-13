import "../../../styles/decision-actions.css";

export default function DecisionActions() {
  return (
    <section className="decision-actions">

      <button className="primary-action">
        Assign Rescue Team
      </button>

      <button className="secondary-action">
        Start Rescue
      </button>

      <button className="outline-action">
        Request Manual Review
      </button>

    </section>
  );
}
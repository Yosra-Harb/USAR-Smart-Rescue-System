import "../../styles/dashboard-widget.css";

type DashboardWidgetProps = {
  title: string;
  children?: React.ReactNode;
};

export default function DashboardWidget({
  title,
  children,
}: DashboardWidgetProps) {
  return (
    <section className="dashboard-widget">

      <header className="dashboard-widget-header">
        <h3>{title}</h3>
      </header>

      <div className="dashboard-widget-body">
        {children}
      </div>

    </section>
  );
}
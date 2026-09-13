import "../styles/main-content.css";

type MainContentProps = {
  children: React.ReactNode;
};

export default function MainContent({
  children,
}: MainContentProps) {
  return (
    <main className="main-content">
      {children}
    </main>
  );
}
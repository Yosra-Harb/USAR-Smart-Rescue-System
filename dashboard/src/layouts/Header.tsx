import "../styles/header.css";

type HeaderProps = {
  title: string;
};

export default function Header({ title }: HeaderProps) {
  return (
    <header className="header">
      <h1>{title}</h1>
    </header>
  );
}
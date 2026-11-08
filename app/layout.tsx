import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Camila Moda | Orçamentos e trabalhos",
  description: "Moda feminina de fabricação própria. Conheça a coleção, solicite um orçamento e acompanhe seu trabalho.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR">
      <body className="antialiased">{children}</body>
    </html>
  );
}

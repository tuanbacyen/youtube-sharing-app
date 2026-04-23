import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Funny Movies",
  description: "YouTube video sharing with real-time notifications",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

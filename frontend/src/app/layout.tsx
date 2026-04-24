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
  const apiUrl = process.env.API_URL || 'http://localhost:3969'
  return (
    <html lang="en">
      <body>
        <script dangerouslySetInnerHTML={{ __html: `window.__API_URL__=${JSON.stringify(apiUrl)}` }} />
        {children}
      </body>
    </html>
  );
}

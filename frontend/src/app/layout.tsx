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
  const wsUrl  = process.env.WS_URL  || apiUrl.replace(/^http/, 'ws')
  return (
    <html lang="en">
      <body>
        <script dangerouslySetInnerHTML={{ __html: `window.__API_URL__=${JSON.stringify(apiUrl)};window.__WS_URL__=${JSON.stringify(wsUrl)}` }} />
        {children}
      </body>
    </html>
  );
}

import type { Metadata } from "next";
import "./globals.css";
import { geistSans, geistMono } from "./fonts";
import { Providers } from "./providers";

export const metadata: Metadata = {
  title: "Wild Guard",
  description: "Generated by Conner",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}

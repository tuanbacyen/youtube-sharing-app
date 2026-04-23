import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  turbopack: { root: __dirname },
  async rewrites() {
    const beUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3969'
    return [
      { source: '/api/:path*', destination: `${beUrl}/api/:path*` },
      { source: '/cable',      destination: `${beUrl}/cable` },
    ]
  },
};

export default nextConfig;

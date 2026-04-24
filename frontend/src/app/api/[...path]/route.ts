import type { NextRequest } from 'next/server'

const BE_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3969'

async function proxy(request: NextRequest, params: Promise<{ path: string[] }>) {
  const { path } = await params
  const url = new URL(`${BE_URL}/api/${path.join('/')}`)
  url.search = request.nextUrl.search

  const headers: Record<string, string> = {}
  request.headers.forEach((value, key) => {
    if (!['host', 'connection', 'transfer-encoding'].includes(key.toLowerCase())) {
      headers[key] = value
    }
  })

  const init: RequestInit & { duplex?: string } = { method: request.method, headers }
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    init.body = request.body
    init.duplex = 'half'
  }

  const res = await fetch(url.toString(), init)
  const resHeaders = new Headers(res.headers)
  resHeaders.delete('transfer-encoding')

  return new Response(res.body, { status: res.status, headers: resHeaders })
}

export const GET    = (req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) => proxy(req, ctx.params)
export const POST   = (req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) => proxy(req, ctx.params)
export const PUT    = (req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) => proxy(req, ctx.params)
export const PATCH  = (req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) => proxy(req, ctx.params)
export const DELETE = (req: NextRequest, ctx: { params: Promise<{ path: string[] }> }) => proxy(req, ctx.params)

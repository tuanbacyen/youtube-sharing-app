import VideoCard from './VideoCard'

export default function VideoList({ videos }) {
  if (videos.length === 0) {
    return <p style={{ textAlign: 'center', color: '#999', marginTop: '60px' }}>No videos shared yet.</p>
  }
  return (
    <div>
      {videos.map(video => <VideoCard key={video.id} video={video} />)}
    </div>
  )
}

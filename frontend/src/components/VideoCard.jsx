export default function VideoCard({ video }) {
  return (
    <div style={styles.card}>
      <div style={styles.embed}>
        <iframe width="300" height="180"
          src={`https://www.youtube.com/embed/${video.youtube_id}`}
          title={video.title} frameBorder="0" allowFullScreen />
      </div>
      <div style={styles.info}>
        <h3 style={styles.title}>{video.title}</h3>
        <p style={styles.meta}>Shared by: {video.shared_by}</p>
        {video.description && (
          <>
            <p style={styles.label}>Description:</p>
            <p style={styles.desc}>{video.description}</p>
          </>
        )}
      </div>
    </div>
  )
}

const styles = {
  card: { display: 'flex', gap: '20px', marginBottom: '32px', paddingBottom: '24px', borderBottom: '1px solid #eee' },
  embed: { flexShrink: 0 },
  info: { flex: 1 },
  title: { color: '#cc0000', marginBottom: '6px', fontSize: '18px' },
  meta: { fontSize: '14px', marginBottom: '8px', color: '#555' },
  label: { fontSize: '14px', fontWeight: 'bold', marginBottom: '4px' },
  desc: { fontSize: '14px', color: '#666', lineHeight: '1.5' }
}

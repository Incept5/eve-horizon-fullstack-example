import { useState, useEffect } from 'react';

interface StatusResponse {
  api: string;
  database: string;
  database_error?: string;
  notes_count: number;
}

export default function App() {
  const [status, setStatus] = useState<StatusResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStatus = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('/api/status');
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setStatus(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch status');
      setStatus(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStatus();
  }, []);

  return (
    <main className="page">
      <header>
        <h1>Eve Horizon Fullstack Example</h1>
        <p>React + NestJS + Postgres</p>
      </header>

      <section className="panel">
        <h2>System Status</h2>

        {loading && <p>Loading status...</p>}

        {error && (
          <div className="status-error">
            <p><strong>Error:</strong> {error}</p>
            <p>Unable to connect to API. Make sure the API is running.</p>
          </div>
        )}

        {status && (
          <div className="status-grid">
            <div className="status-item">
              <span className="status-label">API:</span>
              <span className={`status-badge ${status.api === 'ok' ? 'status-ok' : 'status-error'}`}>
                {status.api === 'ok' ? '✓ Connected' : '✗ Error'}
              </span>
            </div>

            <div className="status-item">
              <span className="status-label">Database:</span>
              <span className={`status-badge ${status.database === 'ok' ? 'status-ok' : 'status-error'}`}>
                {status.database === 'ok' ? '✓ Connected' : '✗ Error'}
              </span>
            </div>

            {status.database === 'ok' && (
              <div className="status-item">
                <span className="status-label">Notes Count:</span>
                <span className="status-value">{status.notes_count}</span>
              </div>
            )}

            {status.database_error && (
              <div className="status-item full-width">
                <span className="status-label">Database Error:</span>
                <span className="status-error">{status.database_error}</span>
              </div>
            )}
          </div>
        )}

        <button type="button" onClick={fetchStatus} disabled={loading}>
          {loading ? 'Refreshing...' : 'Refresh Status'}
        </button>
      </section>

      <section className="panel">
        <p>This is a canonical example repo for Eve Horizon.</p>
        <button type="button">Add your feature</button>
      </section>
    </main>
  );
}

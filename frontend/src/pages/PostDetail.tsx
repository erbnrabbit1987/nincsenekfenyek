import { useParams, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { collectionApi, factcheckApi } from '../lib/api';
import { ArrowLeft, CheckCircle2, ExternalLink, RefreshCw } from 'lucide-react';
import { format } from 'date-fns';
import { hu } from 'date-fns/locale';

export default function PostDetail() {
  const { id } = useParams<{ id: string }>();
  const queryClient = useQueryClient();

  const { data: post, isLoading } = useQuery({
    queryKey: ['post', id],
    queryFn: () => collectionApi.getPost(id!).then(res => res.data),
    enabled: !!id,
  });

  const { data: factcheck } = useQuery({
    queryKey: ['factcheck', id],
    queryFn: () => factcheckApi.getResult(id!).then(res => res.data),
    enabled: !!id,
  });

  const factcheckMutation = useMutation({
    mutationFn: () => factcheckApi.checkPost(id!).then(res => res.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['factcheck', id] });
    },
  });

  const verdictColors: Record<string, string> = {
    verified: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
    true: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
    partially_true: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
    disputed: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200',
    false: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
  };

  const verdictLabels: Record<string, string> = {
    verified: 'Igazolt',
    true: 'Igaz',
    partially_true: 'Részben Igaz',
    disputed: 'Vitatható',
    false: 'Hamis',
  };

  if (isLoading) {
    return <div className="text-center py-12 text-gray-500">Betöltés...</div>;
  }

  if (!post) {
    return <div className="text-center py-12 text-red-500">Poszt nem található</div>;
  }

  return (
    <div className="space-y-6">
      <Link
        to="/posts"
        className="inline-flex items-center text-sm text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200"
      >
        <ArrowLeft className="w-4 h-4 mr-2" />
        Vissza a posztokhoz
      </Link>

      {/* Post Content */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div className="flex items-start justify-between mb-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              {post.title || 'Poszt'}
            </h1>
            <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400">
              <span>{format(new Date(post.posted_at), 'PPP p', { locale: hu })}</span>
              <span className="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded">
                {post.source}
              </span>
            </div>
          </div>
          <button
            onClick={() => factcheckMutation.mutate()}
            disabled={factcheckMutation.isPending}
            className="flex items-center px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50"
          >
            <CheckCircle2 className="w-5 h-5 mr-2" />
            {factcheckMutation.isPending ? 'Ellenőrzés...' : 'Tényellenőrzés'}
          </button>
        </div>

        <div className="prose dark:prose-invert max-w-none">
          <p className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
            {post.content}
          </p>
        </div>

        {post.metadata?.link && (
          <a
            href={post.metadata.link}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-4 inline-flex items-center text-primary-600 hover:text-primary-700"
          >
            <ExternalLink className="w-4 h-4 mr-2" />
            Eredeti poszt megtekintése
          </a>
        )}
      </div>

      {/* Fact-check Result */}
      {factcheck && (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
              Tényellenőrzés Eredménye
            </h2>
            <span
              className={`px-3 py-1 rounded-full text-sm font-medium ${
                verdictColors[factcheck.verdict] || 'bg-gray-100 text-gray-800'
              }`}
            >
              {verdictLabels[factcheck.verdict] || factcheck.verdict}
            </span>
          </div>

          <div className="mb-4">
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">
              Bizonyossági szint: {Math.round(factcheck.confidence * 100)}%
            </p>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div
                className="bg-primary-600 h-2 rounded-full"
                style={{ width: `${factcheck.confidence * 100}%` }}
              />
            </div>
          </div>

          {/* Claims */}
          {factcheck.claims && factcheck.claims.length > 0 && (
            <div className="mb-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
                Kinyert Állítások ({factcheck.claims.length})
              </h3>
              <div className="space-y-2">
                {factcheck.claims.map((claim, index) => (
                  <div
                    key={index}
                    className="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
                  >
                    <p className="text-sm text-gray-700 dark:text-gray-300">
                      {claim.text}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* References */}
          {factcheck.references && factcheck.references.length > 0 && (
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
                Hivatkozások ({factcheck.references.length})
              </h3>
              <div className="space-y-3">
                {factcheck.references.map((ref, index) => (
                  <div
                    key={index}
                    className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        {ref.url ? (
                          <a
                            href={ref.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-primary-600 hover:text-primary-700 font-medium"
                          >
                            {ref.title || ref.url}
                            <ExternalLink className="inline-block w-4 h-4 ml-1" />
                          </a>
                        ) : (
                          <p className="font-medium text-gray-900 dark:text-white">
                            {ref.title}
                          </p>
                        )}
                        {ref.snippet && (
                          <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                            {ref.snippet}
                          </p>
                        )}
                        <div className="mt-2 flex items-center gap-2">
                          <span className="text-xs px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded">
                            {ref.source}
                          </span>
                          <span className="text-xs text-gray-500">
                            Relevancia: {Math.round(ref.relevance_score * 100)}%
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}


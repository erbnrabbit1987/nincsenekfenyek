import { useQuery } from '@tanstack/react-query';
import { factcheckApi } from '../lib/api';
import { Link } from 'react-router-dom';
import { CheckCircle2, XCircle, AlertCircle } from 'lucide-react';
import { format } from 'date-fns';
import { hu } from 'date-fns/locale';
import clsx from 'clsx';

export default function FactChecks() {
  const { data: factchecks, isLoading } = useQuery({
    queryKey: ['factchecks'],
    queryFn: () => factcheckApi.listResults({ limit: 50 }).then(res => res.data),
  });

  const getVerdictIcon = (verdict: string) => {
    switch (verdict) {
      case 'verified':
      case 'true':
        return <CheckCircle2 className="w-5 h-5 text-green-500" />;
      case 'false':
        return <XCircle className="w-5 h-5 text-red-500" />;
      default:
        return <AlertCircle className="w-5 h-5 text-yellow-500" />;
    }
  };

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

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Tényellenőrzések</h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Összes tényellenőrzési eredmény
        </p>
      </div>

      {isLoading ? (
        <div className="text-center py-12 text-gray-500">Betöltés...</div>
      ) : (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
          <div className="divide-y divide-gray-200 dark:divide-gray-700">
            {factchecks && factchecks.length > 0 ? (
              factchecks.map((factcheck) => (
                <Link
                  key={factcheck._id || factcheck.post_id}
                  to={`/posts/${factcheck.post_id}`}
                  className="block px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                >
                  <div className="flex items-start gap-4">
                    <div className="mt-1">{getVerdictIcon(factcheck.verdict)}</div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-2">
                        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                          Poszt #{factcheck.post_id.substring(0, 8)}...
                        </h3>
                        <span
                          className={clsx(
                            'px-3 py-1 rounded-full text-sm font-medium',
                            verdictColors[factcheck.verdict] || 'bg-gray-100 text-gray-800'
                          )}
                        >
                          {verdictLabels[factcheck.verdict] || factcheck.verdict}
                        </span>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400 mb-2">
                        <span>
                          {factcheck.claims?.length || 0} állítás
                        </span>
                        <span>
                          {factcheck.references?.length || 0} hivatkozás
                        </span>
                        <span>
                          Bizonyosság: {Math.round(factcheck.confidence * 100)}%
                        </span>
                      </div>
                      <p className="text-xs text-gray-400">
                        {format(new Date(factcheck.checked_at), 'PPP p', { locale: hu })}
                      </p>
                    </div>
                  </div>
                </Link>
              ))
            ) : (
              <div className="px-6 py-12 text-center text-gray-500">
                Nincsenek tényellenőrzési eredmények
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}


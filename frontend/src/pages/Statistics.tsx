import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { statisticsApi } from '../lib/api';
import { Search, Database, TrendingUp } from 'lucide-react';

export default function Statistics() {
  const [eurostatQuery, setEurostatQuery] = useState('');
  const [kshQuery, setKshQuery] = useState('');

  const { data: eurostatResults, isLoading: eurostatLoading } = useQuery({
    queryKey: ['eurostat', eurostatQuery],
    queryFn: () => statisticsApi.eurostat.search(eurostatQuery).then(res => res.data),
    enabled: eurostatQuery.length > 2,
  });

  const { data: kshResults, isLoading: kshLoading } = useQuery({
    queryKey: ['ksh', kshQuery],
    queryFn: () => statisticsApi.ksh.search(kshQuery).then(res => res.data),
    enabled: kshQuery.length > 2,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Statisztikák</h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          EUROSTAT és KSH statisztikai adatok keresése
        </p>
      </div>

      {/* EUROSTAT Search */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div className="flex items-center gap-3 mb-4">
          <Database className="w-6 h-6 text-primary-600" />
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
            EUROSTAT Keresés
          </h2>
        </div>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={eurostatQuery}
            onChange={(e) => setEurostatQuery(e.target.value)}
            placeholder="Keresés EUROSTAT adatkészletekben..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
          />
        </div>
        {eurostatLoading && (
          <div className="mt-4 text-center text-gray-500">Keresés...</div>
        )}
        {eurostatResults && (
          <div className="mt-4 space-y-2">
            {/* Display results */}
          </div>
        )}
      </div>

      {/* KSH Search */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div className="flex items-center gap-3 mb-4">
          <TrendingUp className="w-6 h-6 text-primary-600" />
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
            KSH Keresés
          </h2>
        </div>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={kshQuery}
            onChange={(e) => setKshQuery(e.target.value)}
            placeholder="Keresés KSH statisztikákban..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
          />
        </div>
        {kshLoading && (
          <div className="mt-4 text-center text-gray-500">Keresés...</div>
        )}
        {kshResults && (
          <div className="mt-4 space-y-2">
            {/* Display results */}
          </div>
        )}
      </div>
    </div>
  );
}


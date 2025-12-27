import { useQuery } from '@tanstack/react-query';
import { healthApi } from '../lib/api';
import { CheckCircle2, AlertCircle, Server, Key } from 'lucide-react';

export default function Settings() {
  const { data: health } = useQuery<{ status: string }>({
    queryKey: ['health'],
    queryFn: async () => {
      const res = await healthApi.check();
      return res.data;
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Beállítások</h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Rendszerbeállítások és API konfiguráció
        </p>
      </div>

      {/* System Status */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div className="flex items-center gap-3 mb-4">
          <Server className="w-6 h-6 text-primary-600" />
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
            Rendszer Állapot
          </h2>
        </div>
        <div className="space-y-3">
          <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
            <span className="text-gray-700 dark:text-gray-300">Backend API</span>
            <div className="flex items-center gap-2">
              {health?.status === 'healthy' ? (
                <>
                  <CheckCircle2 className="w-5 h-5 text-green-500" />
                  <span className="text-green-600 dark:text-green-400">Működik</span>
                </>
              ) : (
                <>
                  <AlertCircle className="w-5 h-5 text-red-500" />
                  <span className="text-red-600 dark:text-red-400">Hiba</span>
                </>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* API Keys Status */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div className="flex items-center gap-3 mb-4">
          <Key className="w-6 h-6 text-primary-600" />
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
            API Kulcsok Állapota
          </h2>
        </div>
        <div className="space-y-3">
          <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
            <span className="text-gray-700 dark:text-gray-300">Google Search API</span>
            <span className="text-sm text-gray-500">Ellenőrizd a backend logokat</span>
          </div>
          <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
            <span className="text-gray-700 dark:text-gray-300">Bing Search API</span>
            <span className="text-sm text-gray-500">Ellenőrizd a backend logokat</span>
          </div>
        </div>
      </div>
    </div>
  );
}


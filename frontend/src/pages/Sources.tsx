import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { sourcesApi, collectionApi, type Source } from '@/lib/api';
import { Plus, Play, Trash2, Edit } from 'lucide-react';
import { useState } from 'react';

export default function Sources() {
  const queryClient = useQueryClient();
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [showAddModal, setShowAddModal] = useState(false);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [selectedSource, setSelectedSource] = useState<Source | null>(null);

  const { data: sources, isLoading } = useQuery<Source[]>({
    queryKey: ['sources'],
    queryFn: async () => {
      const res = await sourcesApi.list();
      return (res.data as any).items || res.data;
    },
  });

  const triggerMutation = useMutation({
    mutationFn: async (sourceId: string) => {
      const res = await collectionApi.trigger(sourceId);
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sources'] });
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });

  const handleTrigger = (sourceId: string) => {
    triggerMutation.mutate(sourceId);
  };

  const sourceTypeLabels: Record<string, string> = {
    facebook: 'Facebook',
    news: 'Hírek',
    rss: 'RSS Feed',
    statistics: 'Statisztikák',
    official_publication: 'Magyar Közlöny',
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Források</h1>
          <p className="mt-2 text-gray-600 dark:text-gray-400">
            Kezeld az adatgyűjtési forrásokat
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
        >
          <Plus className="w-5 h-5 mr-2" />
          Új Forrás
        </button>
      </div>

      {isLoading ? (
        <div className="text-center py-12 text-gray-500">Betöltés...</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {sources && sources.length > 0 ? (
            sources.map((source: Source) => (
              <div
                key={source._id}
                className="bg-white dark:bg-gray-800 rounded-lg shadow p-6"
              >
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                      {source.name || source.identifier}
                    </h3>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      {sourceTypeLabels[source.source_type] || source.source_type}
                    </p>
                  </div>
                  <span
                    className={`px-2 py-1 text-xs rounded-full ${
                      source.is_active
                        ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                    }`}
                  >
                    {source.is_active ? 'Aktív' : 'Inaktív'}
                  </span>
                </div>

                <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  {source.identifier}
                </p>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handleTrigger(source._id!)}
                    disabled={triggerMutation.isPending}
                    className="flex-1 flex items-center justify-center px-3 py-2 text-sm bg-primary-600 text-white rounded hover:bg-primary-700 disabled:opacity-50"
                  >
                    <Play className="w-4 h-4 mr-1" />
                    Gyűjtés
                  </button>
                  <button
                    onClick={() => setSelectedSource(source)}
                    className="p-2 text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200"
                  >
                    <Edit className="w-4 h-4" />
                  </button>
                  <button className="p-2 text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-200">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))
          ) : (
            <div className="col-span-full text-center py-12 text-gray-500">
              Nincsenek források. Adj hozzá egy újat!
            </div>
          )}
        </div>
      )}
    </div>
  );
}


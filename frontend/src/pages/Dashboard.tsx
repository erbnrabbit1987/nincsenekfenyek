import { useQuery } from '@tanstack/react-query';
import { collectionApi, sourcesApi, factcheckApi, type Source, type Post, type FactCheckResult } from '../lib/api.js';
import { FileText, Database, CheckCircle2, Activity } from 'lucide-react';

export default function Dashboard() {
  const { data: sources } = useQuery<Source[]>({
    queryKey: ['sources'],
    queryFn: async () => {
      const res = await sourcesApi.list();
      return (res.data as any).items || res.data;
    },
  });

  const { data: posts } = useQuery<Post[]>({
    queryKey: ['posts', 'recent'],
    queryFn: async () => {
      const res = await collectionApi.getPosts({ limit: 10 });
      return (res.data as any).items || res.data;
    },
  });

  const { data: factchecks } = useQuery<FactCheckResult[]>({
    queryKey: ['factchecks', 'recent'],
    queryFn: async () => {
      const res = await factcheckApi.listResults({ limit: 10 });
      return (res.data as any).items || res.data;
    },
  });

  const stats = [
    {
      name: 'Aktív Források',
      value: sources?.length || 0,
      icon: Database,
      color: 'bg-blue-500',
    },
    {
      name: 'Összes Poszt',
      value: posts?.length || 0,
      icon: FileText,
      color: 'bg-green-500',
    },
    {
      name: 'Tényellenőrzések',
      value: factchecks?.length || 0,
      icon: CheckCircle2,
      color: 'bg-purple-500',
    },
    {
      name: 'Aktivitás',
      value: 'Magas',
      icon: Activity,
      color: 'bg-orange-500',
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Dashboard</h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Áttekintés a tényellenőrző platform állapotáról
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <div
            key={stat.name}
            className="bg-white dark:bg-gray-800 rounded-lg shadow p-6"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
                  {stat.name}
                </p>
                <p className="mt-2 text-3xl font-bold text-gray-900 dark:text-white">
                  {stat.value}
                </p>
              </div>
              <div className={`${stat.color} p-3 rounded-lg`}>
                <stat.icon className="w-6 h-6 text-white" />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Posts */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
            Legutóbbi Posztok
          </h2>
        </div>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          {posts && posts.length > 0 ? (
            posts.map((post: Post) => (
              <div key={post._id} className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <h3 className="text-sm font-medium text-gray-900 dark:text-white">
                      {post.title || post.content.substring(0, 100)}...
                    </h3>
                    <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      {post.source} • {new Date(post.posted_at).toLocaleDateString('hu-HU')}
                    </p>
                  </div>
                  <FileText className="w-5 h-5 text-gray-400" />
                </div>
              </div>
            ))
          ) : (
            <div className="px-6 py-8 text-center text-gray-500 dark:text-gray-400">
              Nincsenek posztok
            </div>
          )}
        </div>
      </div>
    </div>
  );
}


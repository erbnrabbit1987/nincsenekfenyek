import { useQuery } from '@tanstack/react-query';
import { collectionApi, type Post } from '@/lib/api';
import { Link } from 'react-router-dom';
import { ExternalLink, Calendar } from 'lucide-react';
import { format } from 'date-fns';
import { hu } from 'date-fns/locale';

export default function Posts() {
  const { data: posts, isLoading } = useQuery<Post[]>({
    queryKey: ['posts'],
    queryFn: async () => {
      const res = await collectionApi.getPosts({ limit: 50 });
      return (res.data as any).items || res.data;
    },
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Posztok</h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Összes gyűjtött poszt és hír
        </p>
      </div>

      {isLoading ? (
        <div className="text-center py-12 text-gray-500">Betöltés...</div>
      ) : (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
          <div className="divide-y divide-gray-200 dark:divide-gray-700">
            {posts && posts.length > 0 ? (
              posts.map((post: Post) => (
                <Link
                  key={post._id}
                  to={`/posts/${post._id}`}
                  className="block px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                        {post.title || post.content.substring(0, 150)}...
                      </h3>
                      <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                        {post.content.substring(0, 200)}...
                      </p>
                      <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400">
                        <span className="flex items-center gap-1">
                          <Calendar className="w-4 h-4" />
                          {format(new Date(post.posted_at), 'PPP', { locale: hu })}
                        </span>
                        <span className="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded">
                          {post.source}
                        </span>
                      </div>
                    </div>
                    <ExternalLink className="w-5 h-5 text-gray-400 ml-4" />
                  </div>
                </Link>
              ))
            ) : (
              <div className="px-6 py-12 text-center text-gray-500">
                Nincsenek posztok
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}


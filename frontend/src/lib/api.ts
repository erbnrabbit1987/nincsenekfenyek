/**
 * API Client for Nincsenek Fények! Backend
 */
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8095/api';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Types
export interface Source {
  _id?: string;
  source_type: 'facebook' | 'news' | 'rss' | 'statistics' | 'official_publication';
  identifier: string;
  name?: string;
  source_group_id: string;
  config?: Record<string, any>;
  is_active?: boolean;
  schedule?: {
    hours?: number;
    minutes?: number;
    seconds?: number;
    cron?: string;
  };
}

export interface Post {
  _id: string;
  source_id: string;
  source: string;
  source_type: string;
  content: string;
  title?: string;
  posted_at: string;
  collected_at: string;
  metadata?: Record<string, any>;
}

export interface FactCheckResult {
  _id?: string;
  post_id: string;
  claims: Array<{
    text: string;
    type: string;
    confidence: number;
  }>;
  verdict: 'verified' | 'disputed' | 'false' | 'true' | 'partially_true';
  confidence: number;
  references: Array<{
    type: string;
    source: string;
    title?: string;
    url?: string;
    snippet?: string;
    relevance_score: number;
  }>;
  checked_at: string;
  checked_by: string;
}

export interface CollectionResult {
  source_id: string;
  source_type: string;
  posts_found: number;
  posts_saved: number;
  errors: string[];
}

// Sources API
export const sourcesApi = {
  list: () => api.get<{ items: Source[]; total: number; page: number; size: number }>('/sources'),
  get: (id: string) => api.get<Source>(`/sources/${id}`),
  create: (source: Partial<Source>) => api.post<Source>('/sources', source),
  update: (id: string, source: Partial<Source>) => api.put<Source>(`/sources/${id}`, source),
  delete: (id: string) => api.delete(`/sources/${id}`),
};

// Collection API
export const collectionApi = {
  trigger: (sourceId: string, maxPosts?: number) =>
    api.post<CollectionResult>(`/collection/trigger/${sourceId}`, { max_posts: maxPosts }),
  getStatus: (sourceId: string) => api.get(`/collection/status/${sourceId}`),
  getPosts: (params?: { source_id?: string; limit?: number; offset?: number }) =>
    api.get<{ items: Post[]; total: number; page: number; size: number }>('/collection/posts', { params }),
  getPost: (postId: string) => api.get<Post>(`/collection/posts/${postId}`),
};

// Fact-check API
export const factcheckApi = {
  checkPost: (postId: string, manualSources?: string[]) =>
    api.post<FactCheckResult>(`/factcheck/${postId}`, { manual_sources: manualSources }),
  getResult: (postId: string) => api.get<FactCheckResult>(`/factcheck/${postId}`),
  listResults: (params?: { post_id?: string; verdict?: string; limit?: number }) =>
    api.get<{ items: FactCheckResult[]; total: number; page: number; size: number }>('/factcheck/results/list', { params }),
};

// Statistics API
export const statisticsApi = {
  eurostat: {
    search: (query: string) => api.get(`/statistics/eurostat/search?query=${encodeURIComponent(query)}`),
    collect: (datasetCode: string, filters?: Record<string, string[]>) =>
      api.post(`/statistics/eurostat/collect/${datasetCode}`, { filters }),
    getDataset: (datasetCode: string) => api.get(`/statistics/eurostat/dataset/${datasetCode}`),
  },
  ksh: {
    search: (query: string) => api.get(`/statistics/ksh/search?query=${encodeURIComponent(query)}`),
    collect: (datasetCode: string, source?: string) =>
      api.post(`/statistics/ksh/collect/${datasetCode}`, { source }),
    getDataset: (datasetCode: string) => api.get(`/statistics/ksh/dataset/${datasetCode}`),
  },
};

// RSS/MTI API
export const newsApi = {
  mti: {
    collect: (feedType: string, maxItems?: number) =>
      api.post(`/collection/mti/collect?feed_type=${feedType}&max_items=${maxItems || 50}`),
    feeds: () => api.get('/collection/mti/feeds'),
    search: (query: string) => api.get(`/collection/mti/search?query=${encodeURIComponent(query)}`),
  },
  rss: {
    collect: (feedUrl: string, maxItems?: number) =>
      api.post(`/collection/rss/collect?feed_url=${encodeURIComponent(feedUrl)}&max_items=${maxItems || 50}`),
    validate: (feedUrl: string) => api.post(`/collection/rss/validate?feed_url=${encodeURIComponent(feedUrl)}`),
    search: (query: string) => api.get(`/collection/rss/search?query=${encodeURIComponent(query)}`),
  },
  kozlony: {
    collect: (maxItems?: number, year?: number) =>
      api.post(`/collection/kozlony/collect?max_items=${maxItems || 50}${year ? `&year=${year}` : ''}`),
    search: (query: string, year?: number) =>
      api.get(`/collection/kozlony/search?query=${encodeURIComponent(query)}${year ? `&year=${year}` : ''}`),
  },
};

// Health check
export const healthApi = {
  check: () => api.get<{ status: string }>('/health'),
};


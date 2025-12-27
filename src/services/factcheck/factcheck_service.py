"""
Fact-checking Service
Extracts claims, searches for references, and generates fact-check results
"""
import logging
import re
from typing import List, Dict, Any, Optional
from datetime import datetime

try:
    import spacy
    from langdetect import detect
    SPACY_AVAILABLE = True
except ImportError:
    SPACY_AVAILABLE = False
    logging.warning("spaCy or langdetect not available. Fact-checking will be limited.")

from src.models.database import connect_mongodb_sync
from src.models.mongodb_models import Post, FactCheckResult

logger = logging.getLogger(__name__)


class FactCheckService:
    """Service for fact-checking posts"""
    
    def __init__(self):
        self.db = connect_mongodb_sync()
        self.nlp = None
        self._load_nlp_model()
    
    def _load_nlp_model(self):
        """Load Hungarian NLP model"""
        if not SPACY_AVAILABLE:
            logger.warning("spaCy not available, skipping NLP model loading")
            return
        
        try:
            # Try to load Hungarian model
            try:
                self.nlp = spacy.load("hu_core_news_lg")
                logger.info("Loaded Hungarian spaCy model: hu_core_news_lg")
            except OSError:
                try:
                    self.nlp = spacy.load("hu_core_news_sm")
                    logger.info("Loaded Hungarian spaCy model: hu_core_news_sm")
                except OSError:
                    logger.warning(
                        "Hungarian spaCy model not found. "
                        "Please install: python -m spacy download hu_core_news_lg"
                    )
                    # Fallback to English model
                    try:
                        self.nlp = spacy.load("en_core_web_sm")
                        logger.warning("Using English model as fallback")
                    except OSError:
                        logger.error("No spaCy models available")
        except Exception as e:
            logger.error(f"Error loading NLP model: {e}")
    
    def _detect_language(self, text: str) -> str:
        """Detect language of text"""
        try:
            return detect(text)
        except Exception as e:
            logger.debug(f"Error detecting language: {e}")
            return "unknown"
    
    def _extract_claims_with_nlp(self, text: str) -> List[Dict[str, Any]]:
        """
        Extract factual claims from text using NLP
        
        Args:
            text: Text to analyze
            
        Returns:
            List of claim dictionaries
        """
        claims = []
        
        if not self.nlp:
            # Fallback: extract sentences
            sentences = re.split(r'[.!?]+', text)
            for sentence in sentences:
                sentence = sentence.strip()
                if len(sentence) > 20:  # Filter short sentences
                    claims.append({
                        'text': sentence,
                        'type': 'statement',
                        'confidence': 0.5
                    })
            return claims
        
        try:
            doc = self.nlp(text)
            
            # Extract sentences
            for sent in doc.sents:
                sent_text = sent.text.strip()
                if len(sent_text) < 20:
                    continue
                
                # Check if sentence contains factual claims
                # Look for numbers, dates, named entities
                has_numbers = bool(re.search(r'\d+', sent_text))
                has_entities = len(sent.ents) > 0
                has_verbs = any(token.pos_ == "VERB" for token in sent)
                
                if has_numbers or (has_entities and has_verbs):
                    # Extract named entities
                    entities = [
                        {
                            'text': ent.text,
                            'label': ent.label_,
                            'start': ent.start_char,
                            'end': ent.end_char
                        }
                        for ent in sent.ents
                    ]
                    
                    # Extract numbers/dates
                    numbers = re.findall(r'\d+[.,]?\d*', sent_text)
                    
                    claims.append({
                        'text': sent_text,
                        'type': 'factual_claim',
                        'entities': entities,
                        'numbers': numbers,
                        'confidence': 0.7 if has_numbers and has_entities else 0.5
                    })
        except Exception as e:
            logger.error(f"Error extracting claims with NLP: {e}")
        
        return claims
    
    def _search_internal_sources(
        self,
        claim: str,
        keywords: List[str]
    ) -> List[Dict[str, Any]]:
        """
        Search for references in internal sources (posts, articles)
        
        Args:
            claim: Claim text to search for
            keywords: Keywords extracted from claim
            
        Returns:
            List of reference dictionaries
        """
        references = []
        
        try:
            # Search in posts
            query = {"$or": [
                {"content": {"$regex": keyword, "$options": "i"}}
                for keyword in keywords[:3]  # Limit to 3 keywords
            ]}
            
            posts = self.db.posts.find(query).limit(5)
            
            for post_doc in posts:
                post = Post.from_dict(post_doc)
                references.append({
                    'type': 'internal_post',
                    'source': 'internal',
                    'post_id': str(post._id),
                    'content': post.content[:200],  # First 200 chars
                    'posted_at': post.posted_at.isoformat(),
                    'relevance_score': 0.7  # Could be improved with similarity
                })
        
        except Exception as e:
            logger.error(f"Error searching internal sources: {e}")
        
        return references
    
    def _search_external_sources(
        self,
        claim: str,
        keywords: List[str],
        manual_sources: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Search for references in external sources
        
        Args:
            claim: Claim text
            keywords: Keywords
            manual_sources: Manually provided source URLs
            
        Returns:
            List of reference dictionaries
        """
        references = []
        
        # Add manual sources
        if manual_sources:
            for source_url in manual_sources:
                references.append({
                    'type': 'manual',
                    'source': 'user_provided',
                    'url': source_url,
                    'relevance_score': 1.0
                })
        
        # TODO: Implement search engines integration (Google, Bing)
        # TODO: Implement EUROSTAT API integration
        # TODO: Implement fact-checking websites search
        
        return references
    
    def _calculate_verdict(
        self,
        claims: List[Dict[str, Any]],
        references: List[Dict[str, Any]]
    ) -> tuple[str, float]:
        """
        Calculate fact-check verdict and confidence
        
        Args:
            claims: List of extracted claims
            references: List of found references
            
        Returns:
            Tuple of (verdict, confidence)
        """
        if not claims:
            return "verified", 0.3  # Low confidence if no claims found
        
        if not references:
            return "disputed", 0.3  # Disputed if no references found
        
        # Simple scoring algorithm
        # Count supporting vs contradicting references
        supporting = 0
        contradicting = 0
        
        # For now, assume all references are supporting
        # In future, implement sentiment/similarity analysis
        supporting = len(references)
        
        total_references = len(references)
        
        if supporting > contradicting * 2:
            if total_references >= 3:
                return "verified", 0.8
            else:
                return "true", 0.6
        elif contradicting > supporting * 2:
            return "false", 0.7
        elif supporting > contradicting:
            return "partially_true", 0.6
        elif contradicting > supporting:
            return "disputed", 0.5
        else:
            return "disputed", 0.4
    
    def factcheck_post(
        self,
        post: Post,
        manual_sources: Optional[List[str]] = None
    ) -> FactCheckResult:
        """
        Perform fact-checking on a post
        
        Args:
            post: Post object to fact-check
            manual_sources: Optional list of manual source URLs
            
        Returns:
            FactCheckResult object
        """
        logger.info(f"Starting fact-check for post {post._id}")
        
        # Extract claims
        claims = self._extract_claims_with_nlp(post.content)
        logger.info(f"Extracted {len(claims)} claims from post")
        
        if not claims:
            # No claims found, create minimal result
            return FactCheckResult(
                post_id=str(post._id),
                claims=[],
                verdict="verified",
                confidence=0.3,
                references=[],
                checked_by="system",
                metadata={"reason": "no_claims_found"}
            )
        
        # Extract keywords from claims
        all_keywords = []
        for claim in claims:
            # Simple keyword extraction
            words = re.findall(r'\b\w{4,}\b', claim['text'].lower())
            all_keywords.extend(words[:5])  # Top 5 words per claim
        
        # Remove duplicates
        keywords = list(set(all_keywords))[:10]  # Top 10 unique keywords
        
        # Search for references
        internal_refs = []
        for claim in claims:
            claim_keywords = re.findall(r'\b\w{4,}\b', claim['text'].lower())[:3]
            refs = self._search_internal_sources(claim['text'], claim_keywords)
            internal_refs.extend(refs)
        
        external_refs = self._search_external_sources(
            post.content,
            keywords,
            manual_sources
        )
        
        all_references = internal_refs + external_refs
        
        # Calculate verdict
        verdict, confidence = self._calculate_verdict(claims, all_references)
        
        logger.info(
            f"Fact-check completed: verdict={verdict}, "
            f"confidence={confidence}, references={len(all_references)}"
        )
        
        # Create result
        result = FactCheckResult(
            post_id=str(post._id),
            claims=claims,
            verdict=verdict,
            confidence=confidence,
            references=all_references,
            checked_by="system",
            metadata={
                "keywords": keywords,
                "internal_refs_count": len(internal_refs),
                "external_refs_count": len(external_refs)
            }
        )
        
        return result
    
    def save_factcheck_result(self, result: FactCheckResult) -> bool:
        """
        Save fact-check result to database
        
        Args:
            result: FactCheckResult object
            
        Returns:
            True if saved successfully
        """
        try:
            self.db.factcheck_results.insert_one(result.to_dict())
            logger.info(f"Saved fact-check result for post {result.post_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving fact-check result: {e}")
            return False
    
    def get_factcheck_result(self, post_id: str) -> Optional[FactCheckResult]:
        """
        Get fact-check result for a post
        
        Args:
            post_id: Post ID
            
        Returns:
            FactCheckResult or None
        """
        try:
            doc = self.db.factcheck_results.find_one(
                {"post_id": post_id},
                sort=[("checked_at", -1)]  # Get most recent
            )
            if doc:
                return FactCheckResult.from_dict(doc)
        except Exception as e:
            logger.error(f"Error getting fact-check result: {e}")
        
        return None



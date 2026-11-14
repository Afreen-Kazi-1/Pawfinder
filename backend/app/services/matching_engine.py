import re
import math
from datetime import datetime
from typing import Dict, Any, Optional, Tuple, List, Set
from app.core.config import settings

# ---------------------------------------------------------
# Breed Aliases & Equivalence Normalization
# ---------------------------------------------------------
BREED_ALIASES: Dict[str, str] = {
    "german shepherd dog": "german shepherd",
    "alsatian": "german shepherd",
    "gsd": "german shepherd",
    "golden": "golden retriever",
    "lab": "labrador retriever",
    "labrador": "labrador retriever",
    "yellow lab": "labrador retriever",
    "black lab": "labrador retriever",
    "chocolate lab": "labrador retriever",
    "pitbull": "pit bull",
    "american pit bull terrier": "pit bull",
    "staffy": "staffordshire bull terrier",
    "frenchie": "french bulldog",
    "yorkie": "yorkshire terrier",
    "poodle mix": "poodle",
    "doodle": "poodle",
    "goldendoodle": "goldendoodle",
    "labradoodle": "labradoodle",
    "husky": "siberian husky",
    "siamese cat": "siamese",
    "persian cat": "persian",
    "maine coon cat": "maine coon",
    "domestic short hair": "domestic shorthair",
    "dsh": "domestic shorthair",
    "domestic long hair": "domestic longhair",
    "dlh": "domestic longhair",
    "tabby": "domestic shorthair",
}

# ---------------------------------------------------------
# Color Similarity & Families
# ---------------------------------------------------------
COLOR_FAMILIES: Dict[str, Set[str]] = {
    "brown": {"brown", "chocolate", "tan", "fawn", "beige", "chestnut", "liver", "copper"},
    "black": {"black", "ebony", "dark", "charcoal"},
    "white": {"white", "cream", "ivory", "snow", "platinum", "blonde"},
    "golden": {"golden", "gold", "yellow", "blond", "blonde", "wheat"},
    "gray": {"gray", "grey", "silver", "blue", "slate", "smoke", "ash"},
    "red": {"red", "ginger", "orange", "rust", "ruby", "copper", "apricot"},
}


class MatchingEngine:
    """Automated deterministic Pet Matching Engine.
    Evaluates lost vs. found reports across 6 configurable weighted criteria:
      1. Animal Type (25%)
      2. Breed (15%)
      3. Color (15%)
      4. Location Proximity (20%)
      5. Date Proximity (10%)
      6. Distinguishing Features & Description (15%)
    """

    def __init__(
        self,
        weight_animal_type: float = settings.WEIGHT_ANIMAL_TYPE,
        weight_breed: float = settings.WEIGHT_BREED_SIMILARITY,
        weight_color: float = settings.WEIGHT_COLOR_SIMILARITY,
        weight_location: float = settings.WEIGHT_LOCATION_PROXIMITY,
        weight_date: float = settings.WEIGHT_DATE_PROXIMITY,
        weight_description: float = settings.WEIGHT_FEATURES_DESCRIPTION,
        threshold_high: float = settings.MATCH_THRESHOLD_HIGH,
        threshold_possible: float = settings.MATCH_THRESHOLD_POSSIBLE,
    ):
        self.weights = {
            "animal_type": weight_animal_type,
            "breed": weight_breed,
            "color": weight_color,
            "location": weight_location,
            "date": weight_date,
            "description": weight_description,
        }
        self.threshold_high = threshold_high
        self.threshold_possible = threshold_possible

    # ---------------------------------------------------------
    # 1. Animal Type Scoring (0 - 100)
    # ---------------------------------------------------------
    def score_animal_type(self, type1: Optional[str], type2: Optional[str]) -> Tuple[float, str, bool]:
        """Exact match = 100, Incompatible = 0."""
        if not type1 or not type2:
            return 0.0, "Missing animal type information.", False

        norm1 = type1.strip().lower()
        norm2 = type2.strip().lower()

        if norm1 == norm2:
            return 100.0, f"Exact animal type match: {type1.title()}.", True
        return 0.0, f"Incompatible animal types: {type1.title()} vs {type2.title()}.", True

    # ---------------------------------------------------------
    # 2. Breed Scoring (0 - 100)
    # ---------------------------------------------------------
    def score_breed(self, breed1: Optional[str], breed2: Optional[str]) -> Tuple[float, str, bool]:
        """Normalizes case, whitespace, aliases, and handles unknown gracefully."""
        b1 = self._normalize_breed(breed1)
        b2 = self._normalize_breed(breed2)

        # If either is missing or marked as unknown/mixed/other
        is_unknown_1 = not b1 or b1 in {"unknown", "mixed", "other", "mutt"}
        is_unknown_2 = not b2 or b2 in {"unknown", "mixed", "other", "mutt"}

        if is_unknown_1 and is_unknown_2:
            # Both unknown -> active component weight policy: neutral 50 score
            return 50.0, "Both reports have unspecified or unknown breeds.", True
        if is_unknown_1 or is_unknown_2:
            known = breed1 if not is_unknown_1 else breed2
            return 60.0, f"One breed is unknown; could match {known}.", True

        if b1 == b2:
            return 100.0, f"Exact breed match: {breed1}.", True

        # Check partial overlap (e.g. 'Labrador Retriever' vs 'Retriever')
        tokens1 = set(b1.split())
        tokens2 = set(b2.split())
        intersection = tokens1.intersection(tokens2)
        if intersection:
            score = 75.0
            return score, f"Breed similarity overlap ({', '.join(intersection)}).", True

        return 10.0, f"Different breeds ({breed1} vs {breed2}).", True

    def _normalize_breed(self, breed: Optional[str]) -> str:
        if not breed:
            return ""
        norm = re.sub(r"[^\w\s]", "", breed.strip().lower())
        norm = " ".join(norm.split())
        return BREED_ALIASES.get(norm, norm)

    # ---------------------------------------------------------
    # 3. Color Scoring (0 - 100)
    # ---------------------------------------------------------
    def score_color(self, color1: Optional[str], color2: Optional[str]) -> Tuple[float, str, bool]:
        """Extracts color words, compares exact words and color family matches."""
        if not color1 or not color2:
            return 50.0, "Color information partially or completely missing.", True

        tokens1 = self._extract_color_tokens(color1)
        tokens2 = self._extract_color_tokens(color2)

        if not tokens1 or not tokens2:
            return 50.0, "Unrecognized color tokens.", True

        exact_intersection = tokens1.intersection(tokens2)
        if exact_intersection:
            ratio = len(exact_intersection) / max(len(tokens1), len(tokens2))
            score = round(70.0 + (30.0 * ratio), 1)
            return score, f"Matching colors: {', '.join(exact_intersection)}.", True

        # Check color families (e.g. 'tan' vs 'brown', 'cream' vs 'white')
        fam1 = self._get_color_families(tokens1)
        fam2 = self._get_color_families(tokens2)
        fam_intersection = fam1.intersection(fam2)
        if fam_intersection:
            return 70.0, f"Compatible color family match: {', '.join(fam_intersection)}.", True

        return 15.0, f"Different color descriptions ({color1} vs {color2}).", True

    def _extract_color_tokens(self, text: str) -> Set[str]:
        cleaned = re.sub(r"[^\w\s]", " ", text.lower())
        tokens = cleaned.split()
        noise = {"and", "with", "spots", "markings", "pattern", "coat", "fur", "patches", "mostly", "light", "dark"}
        return {t for t in tokens if t not in noise}

    def _get_color_families(self, tokens: Set[str]) -> Set[str]:
        families = set()
        for t in tokens:
            for fam, members in COLOR_FAMILIES.items():
                if t in members or t == fam:
                    families.add(fam)
        return families

    # ---------------------------------------------------------
    # 4. Location Proximity Scoring (0 - 100)
    # ---------------------------------------------------------
    def score_location(
        self,
        lat1: Optional[float],
        lon1: Optional[float],
        lat2: Optional[float],
        lon2: Optional[float],
    ) -> Tuple[float, str, bool]:
        """Haversine distance scoring:
          <= 1 km  -> 100
          <= 3 km  -> 90
          <= 5 km  -> 80
          <= 10 km -> 65
          <= 20 km -> 45
          <= 50 km -> 25
          > 50 km  -> exponential decay down to 0
        """
        if lat1 is None or lon1 is None or lat2 is None or lon2 is None:
            return 0.0, "Coordinates unavailable for one or both reports.", False

        dist_km = self.haversine(lat1, lon1, lat2, lon2)

        if dist_km <= 1.0:
            score = 100.0
        elif dist_km <= 3.0:
            score = 90.0
        elif dist_km <= 5.0:
            score = 80.0
        elif dist_km <= 10.0:
            score = 65.0
        elif dist_km <= 20.0:
            score = 45.0
        elif dist_km <= 50.0:
            score = 25.0
        else:
            # Rapid decay beyond 50km
            score = max(0.0, round(25.0 * math.exp(-0.05 * (dist_km - 50.0)), 1))

        return score, f"Distance between locations is {dist_km:.1f} km.", True

    @staticmethod
    def haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371.0
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(math.radians(lat1))
            * math.cos(math.radians(lat2))
            * math.sin(dlon / 2) ** 2
        )
        return 2 * R * math.asin(math.sqrt(a))

    # ---------------------------------------------------------
    # 5. Date Proximity Scoring (0 - 100)
    # ---------------------------------------------------------
    def score_date(self, dt_lost: Optional[datetime], dt_found: Optional[datetime]) -> Tuple[float, str, bool]:
        """Compares last-seen and found event dates.
        Ideally dt_found >= dt_lost (found after lost).
        If found happened before lost, checks if within 2 days (reporting inaccuracy) else penalty.
        """
        if not dt_lost or not dt_found:
            return 50.0, "Date information missing for comparison.", False

        # Normalize timezones
        d1 = dt_lost.replace(tzinfo=None)
        d2 = dt_found.replace(tzinfo=None)

        diff_days = (d2 - d1).total_seconds() / 86400.0

        if -1.0 <= diff_days <= 1.0:
            # Same day or adjacent day
            score = 100.0
            explanation = "Events occurred on or adjacent to the same day."
        elif 1.0 < diff_days <= 3.0:
            score = 90.0
            explanation = f"Found {diff_days:.1f} days after lost."
        elif 3.0 < diff_days <= 7.0:
            score = 80.0
            explanation = f"Found within a week ({diff_days:.1f} days)."
        elif 7.0 < diff_days <= 14.0:
            score = 65.0
            explanation = f"Found within two weeks ({diff_days:.1f} days)."
        elif 14.0 < diff_days <= 30.0:
            score = 50.0
            explanation = f"Found within one month ({diff_days:.1f} days)."
        elif 30.0 < diff_days <= 90.0:
            score = 30.0
            explanation = f"Found within 3 months ({diff_days:.1f} days)."
        elif diff_days > 90.0:
            score = max(5.0, round(30.0 * math.exp(-0.01 * (diff_days - 90.0)), 1))
            explanation = f"Large date discrepancy ({diff_days:.0f} days apart)."
        else:
            # Negative diff: found report dated before lost report
            abs_diff = abs(diff_days)
            if abs_diff <= 2.0:
                score = 70.0
                explanation = f"Found reported {abs_diff:.1f} days before lost date (acceptable variance)."
            else:
                score = max(0.0, round(40.0 - (10.0 * abs_diff), 1))
                explanation = f"Found date is earlier than lost date by {abs_diff:.1f} days."

        return score, explanation, True

    # ---------------------------------------------------------
    # 6. Distinguishing Features & Description (0 - 100)
    # ---------------------------------------------------------
    def score_description(
        self,
        feat1: str,
        desc1: str,
        feat2: str,
        desc2: str,
    ) -> Tuple[float, str, bool]:
        """Token-based Jaccard / Cosine similarity over normalized text."""
        combined1 = f"{feat1 or ''} {desc1 or ''}".strip().lower()
        combined2 = f"{feat2 or ''} {desc2 or ''}".strip().lower()

        if not combined1 and not combined2:
            return 50.0, "No descriptive features provided in either report.", True
        if not combined1 or not combined2:
            return 50.0, "One report has no descriptive text.", True

        tok1 = self._tokenize(combined1)
        tok2 = self._tokenize(combined2)

        if not tok1 or not tok2:
            return 50.0, "Descriptions consist only of stop words.", True

        intersection = tok1.intersection(tok2)
        union = tok1.union(tok2)
        jaccard = len(intersection) / len(union)

        if jaccard >= 0.5:
            score = 100.0
        elif jaccard >= 0.3:
            score = 85.0
        elif jaccard >= 0.15:
            score = 70.0
        elif jaccard > 0.05:
            score = 55.0
        elif intersection:
            score = 45.0
        else:
            score = 25.0

        matched_words = list(intersection)[:4]
        match_desc = f"Matched keywords: {', '.join(matched_words)}" if matched_words else "No distinctive keyword overlap"
        return score, f"Text similarity {jaccard:.2f}. {match_desc}.", True

    def _tokenize(self, text: str) -> Set[str]:
        words = re.findall(r"\b[a-z]{3,}\b", text.lower())
        stopwords = {
            "the", "and", "with", "was", "for", "that", "this", "from",
            "have", "has", "had", "are", "were", "been", "very", "last",
            "seen", "found", "lost", "near", "area", "please", "help",
            "call", "contact", "about", "around",
        }
        return {w for w in words if w not in stopwords}

    # ---------------------------------------------------------
    # Master Evaluation Function
    # ---------------------------------------------------------
    def evaluate(self, lost_report: Any, found_report: Any) -> Dict[str, Any]:
        """Calculates component scores and weighted final score.
        Normalizes by active component weights (missing data policy).
        """
        # 1. Animal Type
        s_animal, exp_animal, active_animal = self.score_animal_type(
            lost_report.animal_type, found_report.animal_type
        )
        # If animal types are incompatible, immediate rejection
        if s_animal == 0.0 and active_animal:
            return {
                "match_score": 0.0,
                "match_category": "No match",
                "is_match": False,
                "reasons": {
                    "animal_type": {"score": 0.0, "explanation": exp_animal},
                    "final_score": 0.0,
                    "explanation": "Incompatible animal types.",
                },
            }

        # 2. Breed
        s_breed, exp_breed, active_breed = self.score_breed(
            lost_report.breed, found_report.breed
        )

        # 3. Color
        s_color, exp_color, active_color = self.score_color(
            lost_report.color, found_report.color
        )

        # 4. Location
        s_loc, exp_loc, active_loc = self.score_location(
            lost_report.latitude, lost_report.longitude,
            found_report.latitude, found_report.longitude,
        )

        # 5. Date
        s_date, exp_date, active_date = self.score_date(
            lost_report.event_datetime, found_report.event_datetime
        )

        # 6. Description
        s_desc, exp_desc, active_desc = self.score_description(
            lost_report.distinguishing_features, lost_report.description,
            found_report.distinguishing_features, found_report.description,
        )

        components = {
            "animal_type": (s_animal, self.weights["animal_type"], active_animal, exp_animal),
            "breed": (s_breed, self.weights["breed"], active_breed, exp_breed),
            "color": (s_color, self.weights["color"], active_color, exp_color),
            "location": (s_loc, self.weights["location"], active_loc, exp_loc),
            "date": (s_date, self.weights["date"], active_date, exp_date),
            "description": (s_desc, self.weights["description"], active_desc, exp_desc),
        }

        weighted_sum = 0.0
        active_weight_sum = 0.0

        reasons = {}
        for key, (score, weight, is_active, explanation) in components.items():
            reasons[key] = {
                "score": round(score, 1),
                "weight": weight,
                "active": is_active,
                "explanation": explanation,
            }
            if is_active:
                weighted_sum += score * weight
                active_weight_sum += weight

        final_score = (
            round(weighted_sum / active_weight_sum, 1)
            if active_weight_sum > 0
            else 0.0
        )
        final_score = min(100.0, max(0.0, final_score))

        # Classification
        if final_score >= self.threshold_high:
            category = "High potential match"
            is_match = True
        elif final_score >= self.threshold_possible:
            category = "Possible match"
            is_match = True
        else:
            category = "Below threshold"
            is_match = False

        reasons["final_score"] = final_score
        reasons["match_category"] = category

        return {
            "match_score": final_score,
            "match_category": category,
            "is_match": is_match,
            "reasons": reasons,
        }


#include "CohesionRule.h"
#include <glm/glm.hpp>

glm::vec2 CohesionRule::computeForce(const std::vector<BoidView>& neighborhood, const BoidView& boid) {
  glm::vec2 cohesionForce(0.f);

  // glm::length(vec) returns the length of a vector,
  // glm::normalize(vec) returns the normalized vector (length 1) in the same direction as vec.

  // begin solution
  glm::vec2 cm(0.f);
  int count = 0;

  if (neighborhood.empty()) {
    return cohesionForce;
  }

  for (const BoidView& other : neighborhood) {
    cm += other.position;
  }
  cm /= static_cast<float>(neighborhood.size());

  glm::vec2 towardCenter = cm - boid.position;

  if (glm::length(towardCenter) > 0.00001f) {
    cohesionForce = glm::normalize(towardCenter);
  }

  // end solution

  return cohesionForce;
}

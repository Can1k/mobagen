#include "CohesionRule.h"
#include <glm/glm.hpp>

glm::vec2 CohesionRule::computeForce(const std::vector<BoidView>& neighborhood, const BoidView& boid) {
  glm::vec2 cohesionForce(0.f);

  // glm::length(vec) returns the length of a vector,
  // glm::normalize(vec) returns the normalized vector (length 1) in the same direction as vec.

  // begin solution
  glm::vec2 cm = {0,0};
  int count = 0;

  if (neighborhood.empty()) {
    return cohesionForce;
  }

  for (const BoidView& neighbor : neighborhood) {
    float dist = glm::distance(boid.position, neighbor.position);
    
  }

  // end solution

  return cohesionForce;
}

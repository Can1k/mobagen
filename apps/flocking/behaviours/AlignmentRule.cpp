#include "AlignmentRule.h"
#include <glm/glm.hpp>

glm::vec2 AlignmentRule::computeForce(const std::vector<BoidView>& neighborhood, const BoidView& boid) {
  glm::vec2 averageVelocity(0.f);
  // glm::vec2 can be divided by a float, which will divide each component of the vector by that float.

  // begin solution
  // neighborhood is pre-filtered by World.cpp
    if(neighborhood.empty()) {
        return averageVelocity;
    }

    for (const BoidView& neighbor : neighborhood) {
        averageVelocity += neighbor.velocity; // Fa = sum of neighbour velocities
    }

    averageVelocity /= static_cast<float>(neighborhood.size());

  return averageVelocity;
  // end solution
}

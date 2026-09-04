#include "SeparationRule.h"
#include "imgui.h"
#include <glm/glm.hpp>

glm::vec2 SeparationRule::computeForce(const std::vector<BoidView>& neighborhood, const BoidView& boid) {
  glm::vec2 separatingForce(0.f);

  // the header have the desiredMinimalDistance member variable, which is the distance that the boids should try to maintain from each other.
  // glm::length(vec) returns the length of a vector,
  // glm::normalize(vec) returns the normalized vector (length 1) in the same direction as vec.
  // multiply by (desiredMinimalDistance / distance) is the proportionality factor that makes the force stronger when the boids are closer together, and weaker when they are farther apart.

  // begin solution
  float maxForce = 5.f;

  for (const BoidView& other : neighborhood) {
    glm::vec2 vec = boid.position - other.position;
    float mag = glm::length(vec);

    if (mag > 0.0001f) {
      glm::vec2 hat = vec / mag;
      separatingForce += hat * (desiredMinimalDistance / mag);
    }
  }

  float total = glm::length(separatingForce);
  if (total > maxForce && total > 0.0001) {
    separatingForce = separatingForce / total * maxForce;
  }

  // distance = |p2p1|
  // direction = ^(p2p1)

  // end solution

  return separatingForce;
}

bool SeparationRule::drawImguiRuleExtra() {
  bool valueHasChanged = false;
  if (ImGui::DragFloat("Desired Separation", &desiredMinimalDistance, 0.05f)) {
    valueHasChanged = true;
  }
  return valueHasChanged;
}

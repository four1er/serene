/* -*- C++ -*-
 * Serene Programming Language
 *
 * Copyright (c) 2019-2023 Sameer Rahmani <lxsameer@gnu.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <iomanip>
#include <iostream>
#include <memory>

struct Vec3 {
  int x, y, z;

  // following constructor is no longer needed since C++20
  Vec3(int x = 0, int y = 0, int z = 0) noexcept : x(x), y(y), z(z) {}

  friend std::ostream &operator<<(std::ostream &os, const Vec3 &v) {
    return os << "{ x=" << v.x << ", y=" << v.y << ", z=" << v.z << " }";
  }
};

int main() {
  // Use the default constructor.
  std::unique_ptr<Vec3> v1 = std::make_unique<Vec3>();
  // Use the constructor that matches these arguments
  std::unique_ptr<Vec3> v2 = std::make_unique<Vec3>(0, 1, 2);
  // Create a unique_ptr to an array of 5 elements
  std::unique_ptr<Vec3[]> v3 = std::make_unique<Vec3[]>(5);

  std::cout << "make_unique<Vec3>():      " << *v1 << '\n'
            << "make_unique<Vec3>(0,1,2): " << *v2 << '\n'
            << "make_unique<Vec3[]>(5):   ";
  for (int i = 0; i < 5; i++)
    std::cout << std::setw(i ? 30 : 0) << v3[static_cast<size_t>(i)] << '\n';
}

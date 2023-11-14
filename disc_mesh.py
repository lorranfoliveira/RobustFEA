import shapely as sp
import numpy as np
import ezdxf
from itertools import combinations
import loguru
from tqdm import tqdm


class FlowerMesh:
    def __init__(self, filename, r1, r2, angular_div, radial_div):
        """

        :param r1: radius of the inner circle
        :param r2: radius of the outer circle
        :param angular_div: number of divisions in the inner circle

        """
        self.filename = filename
        self.r1 = r1
        self.r2 = r2
        self.angular_div = angular_div
        self.radial_div = radial_div

        self.points = None
        self.elements = []

        self.inner_circle = sp.geometry.Point(0, 0).buffer(r1)
        self.outer_circle = sp.geometry.Point(0, 0).buffer(r2)
        self.geometry = self.outer_circle.difference(self.inner_circle).buffer(1e-2 * abs(r2 - r1))

    def generate_structure(self):
        self.generate_points()
        self.generate_elements()
        self.generate_dxf()
        self.generate_npz()

    def generate_points(self):
        angles = np.linspace(0, 2 * np.pi, self.angular_div, endpoint=False)
        hd = np.linspace(self.r1, self.r2, self.radial_div)

        self.points = []

        for h in hd:
            if np.isclose(h, 0):
                self.points.append([0, 0])
            else:
                for angle in angles:
                    x = h * np.cos(angle)
                    y = h * np.sin(angle)
                    pt = [x, y]
                    self.points.append(pt)

        self.points = np.array(self.points)

    def verify_collinearity(self, el1, el2):
        """
        Check if two elements are collinear
        :param el1: first element
        :param el2: second element
        :return: True if collinear, False otherwise
        """
        p1, p2 = self.points[el1[0]], self.points[el1[1]]
        p3, p4 = self.points[el2[0]], self.points[el2[1]]

        length1 = np.linalg.norm(p1 - p2)
        length2 = np.linalg.norm(p3 - p4)

        if length1 > length2:
            line1 = sp.geometry.LineString([p1, p2]).buffer(1e-6)
            line2 = sp.geometry.LineString([p3, p4])
        else:
            line1 = sp.geometry.LineString([p3, p4]).buffer(1e-6)
            line2 = sp.geometry.LineString([p1, p2])

        return line1.contains(line2)

    def generate_elements(self):
        loguru.logger.info('Generating elements...')

        for comb in tqdm(list(combinations(range(self.points.shape[0]), 2))):
            i, j = comb
            line = sp.geometry.LineString([self.points[i], self.points[j]])

            for el in self.elements:
                if self.verify_collinearity(comb, el):
                    break
            else:
                if self.geometry.contains(line):
                    self.elements.append(comb)

        loguru.logger.info(f'Generated {len(self.elements)} elements and {self.points.shape[0]} nodes.')

    def generate_dxf(self):
        loguru.logger.info('Generating DXF file...')
        doc = ezdxf.new()
        msp = doc.modelspace()

        for el in self.elements:
            pt = self.points[el, :]
            msp.add_line(*pt)

        doc.saveas(f'{self.filename}.dxf')
        loguru.logger.info('Done!')

    def generate_npz(self):
        np.savez(f'{self.filename}.npz', self.points, np.array(self.elements))


if __name__ == '__main__':
    mesh = FlowerMesh('flower_1', 0, 100, 12, 5)
    mesh.generate_structure()

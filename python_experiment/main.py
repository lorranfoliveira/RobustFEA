from matplotlib import pyplot as plt
import numpy as np
from math import sqrt, atan2, pi, cos, sin
import matplotlib
import sys

matplotlib.use('TkAgg')

plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["font.size"] = 12


def smooth_max(x, y, mu):
    return (x + y + sqrt((x - y) ** 2 + mu ** 2)) / 2


class Example:
    # Design data
    ...

    # Optimization data
    V = 1
    BETA = 0.0
    THETA_R = np.pi / 6
    MU = 0.0
    MU_THETA = 0.0

    # Plot data
    N_POINTS = 1000
    N_CONTOURS = 20
    X_PLOT_MIN = 3e-2
    X_PLOT_MAX = 0.20
    Y_PLOT_MIN = 3e-2
    Y_PLOT_MAX = 0.20

    xc_min = 0
    yc_min = 0
    c_min = 0

    def txx(self, x1, x2) -> float:
        pass

    def tyy(self, x1, x2) -> float:
        pass

    def txy(self, x1, x2) -> float:
        pass

    def mu(self, x1, x2):
        if np.isclose(self.MU, 0.0):
            self.MU = self.BETA * (self.txx(x1, x2) + self.tyy(x1, x2)) / 2
        return self.MU

    def c_theta(self, x1, x2, theta):
        txx = self.txx(x1, x2)
        tyy = self.tyy(x1, x2)
        txy = self.txy(x1, x2)

        return (txx + tyy) / 2 + (txx - tyy) / 2 * np.cos(2 * theta) + txy * np.sin(2 * theta)

    def thetas_lim(self, x1, x2):
        txx = self.txx(x1, x2)
        tyy = self.tyy(x1, x2)
        txy = self.txy(x1, x2)

        theta_cr1 = atan2(2 * txy, txx - tyy) / 2
        theta_cr2 = theta_cr1 - np.sign(theta_cr1 + sys.float_info.epsilon) * pi / 2

        t1 = min(max(theta_cr1, -self.THETA_R), self.THETA_R)
        t2 = min(max(theta_cr2, -self.THETA_R), self.THETA_R)

        return t1, t2

    def c_ef(self, x1, x2):
        theta_1, theta_2 = self.thetas_lim(x1, x2)
        c1 = self.c_theta(x1, x2, theta_1)
        c2 = self.c_theta(x1, x2, theta_2)

        vc = self.volume_constraint(x1, x2)

        return smooth_max(c1, c2, self.mu(x1, x2)) if vc < 0 else np.nan

    def volume_constraint(self, x1, x2) -> float:
        pass

    def plot_contour(self):
        x = np.linspace(self.X_PLOT_MIN, self.X_PLOT_MAX, self.N_POINTS)
        y = np.linspace(self.Y_PLOT_MIN, self.Y_PLOT_MAX, self.N_POINTS)

        x_mesh, y_mesh = np.meshgrid(x, y)
        z_mesh = np.zeros((self.N_POINTS, self.N_POINTS))

        x1_z_min = 0
        x2_z_min = 0
        z_min = np.inf

        fig, ax = plt.subplots()

        for i in range(self.N_POINTS):
            for j in range(self.N_POINTS):
                z_mesh[i, j] = self.c_ef(x_mesh[i, j], y_mesh[i, j])
                if z_mesh[i, j] is not np.nan:
                    if z_mesh[i, j] < z_min:
                        z_min = z_mesh[i, j]
                        x1_z_min = x_mesh[i, j]
                        x2_z_min = y_mesh[i, j]

        ax.contour(x_mesh, y_mesh, z_mesh, self.N_CONTOURS, linewidths=0.4, linestyles='solid', colors='k')
        cont = ax.contourf(x_mesh, y_mesh, z_mesh, self.N_CONTOURS, cmap='jet')
        ax.scatter(x1_z_min, x2_z_min, marker='o', color='orange', s=40, edgecolors='k', linewidths=0.5,
                   label=f'Cmin: {np.nanmin(z_mesh):.2f}')

        print(f'txx: {self.txx(x1_z_min, x2_z_min)}\n'
              f'tyy: {self.tyy(x1_z_min, x2_z_min)}\n'
              f'txy: {self.txy(x1_z_min, x2_z_min)}\n')

        self.xc_min = x1_z_min
        self.yc_min = x2_z_min
        self.c_min = np.nanmin(z_mesh)

        plt.colorbar(cont, label='Compliance')
        plt.xlabel('x1')
        plt.ylabel('x2')
        plt.xticks(np.linspace(self.X_PLOT_MIN, self.X_PLOT_MAX, 5).round(2))
        plt.yticks(np.linspace(self.Y_PLOT_MIN, self.Y_PLOT_MAX, 5).round(2))
        # lim
        ax.set_xlim(self.X_PLOT_MIN, self.X_PLOT_MAX)
        ax.set_ylim(self.X_PLOT_MIN, self.X_PLOT_MAX)

        plt.title(f'θr={np.degrees(self.THETA_R):.2f}°   β={self.BETA:.2f}')

        plt.axis('equal')
        plt.legend()
        plt.show()

    def plot_2d(self):
        x = np.linspace(0.010768, 0.01077, self.N_POINTS ** 2)
        y_func = np.vectorize(self.c_ef)
        y = y_func(x, 0.035)

        plt.plot(x, y)
        plt.show()
        plt.xlabel('x1')
        plt.ylabel('Compliance')


class Cross(Example):
    # Design data
    L1 = 2
    L2 = 2
    E = 1
    F1 = 1
    F2 = 1

    # Optimization data
    V = 1
    BETA = 0.5
    THETA_R = np.pi / 2
    MU = 0.0

    # Plot data
    N_POINTS = 100
    N_CONTOURS = 10
    X_PLOT_MIN = 3e-2
    X_PLOT_MAX = 0.20
    Y_PLOT_MIN = 3e-2
    Y_PLOT_MAX = 0.20

    def txx(self, x1, x2):
        return self.F1 ** 2 * self.L1 / (2 * self.E * x1)

    def tyy(self, x1, x2):
        return self.F2 ** 2 * self.L2 / (2 * self.E * x2)

    def txy(self, x1, x2):
        return 0

    def volume_constraint(self, x1, x2):
        return 2 * (x1 * self.L1 + x2 * self.L2) - self.V


class Example2(Example):
    # Design data
    L1 = 21.54065923
    L2 = 20.09975124
    PHI_1 = atan2(-2 - (-10), 20 - 0)
    PHI_2 = atan2(-2, 20)

    # Optimization data
    V = 1
    BETA = 0.0
    THETA_R = np.pi / 10
    MU = 0.0

    # Plot data
    N_POINTS = 500
    N_CONTOURS = 10
    X_PLOT_MIN = 0.005
    X_PLOT_MAX = 0.04
    Y_PLOT_MIN = 0.005
    Y_PLOT_MAX = 0.04

    def txx(self, x1, x2):
        return 1 / (x1 * cos(self.PHI_1) ** 2 / self.L1 + x2 * cos(self.PHI_2) ** 2 / self.L2) + (
                x1 * cos(self.PHI_1) * sin(self.PHI_1) / self.L1 + x2 * cos(self.PHI_2) * sin(
            self.PHI_2) / self.L2) ** 2 / (
                (x1 * cos(self.PHI_1) ** 2 / self.L1 + x2 * cos(self.PHI_2) ** 2 / self.L2) ** 2 * (
                x1 * sin(self.PHI_1) ** 2 / self.L1 + x2 * sin(self.PHI_2) ** 2 / self.L2 - (
                x1 * cos(self.PHI_1) * sin(self.PHI_1) / self.L1 + x2 * cos(self.PHI_2) * sin(
            self.PHI_2) / self.L2) ** 2 / (
                        x1 * cos(self.PHI_1) ** 2 / self.L1 + x2 * cos(self.PHI_2) ** 2 / self.L2)))

    def tyy(self, x1, x2):
        return 1 / (x1 * sin(self.PHI_1) ** 2 / self.L1 + x2 * sin(self.PHI_2) ** 2 / self.L2 - (
                x1 * cos(self.PHI_1) * sin(self.PHI_1) / self.L1 + x2 * cos(self.PHI_2) * sin(
            self.PHI_2) / self.L2) ** 2 / (
                            x1 * cos(self.PHI_1) ** 2 / self.L1 + x2 * cos(self.PHI_2) ** 2 / self.L2))

    def txy(self, x1, x2):
        return -(x1 * cos(self.PHI_1) * sin(self.PHI_1) / self.L1 + x2 * cos(self.PHI_2) * sin(
            self.PHI_2) / self.L2) / ((x1 * cos(self.PHI_1) ** 2 / self.L1 + x2 * cos(self.PHI_2) ** 2 / self.L2) * (
                x1 * sin(self.PHI_1) ** 2 / self.L1 + x2 * sin(self.PHI_2) ** 2 / self.L2 - (
                x1 * cos(self.PHI_1) * sin(self.PHI_1) / self.L1 + x2 * cos(self.PHI_2) * sin(
            self.PHI_2) / self.L2) ** 2 / (
                        x1 * cos(self.PHI_1) ** 2 / self.L1 + x2 * cos(self.PHI_2) ** 2 / self.L2)))

    def volume_constraint(self, x1, x2):
        return x1 * self.L1 + x2 * self.L2 - self.V


ex = Example2()
ex.BETA = 0.1
ex.N_CONTOURS = 30
ex.THETA_R = pi / 12
ex.plot_contour()
ex.plot_2d()

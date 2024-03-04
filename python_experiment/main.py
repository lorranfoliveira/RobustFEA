from matplotlib import pyplot as plt
import numpy as np
from math import sqrt, atan2, pi, cos, sin
import matplotlib

matplotlib.use('TkAgg')

plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["font.size"] = 12


class Example:
    # Design data
    ...

    # Optimization data
    V = 1
    BETA = 0.0
    THETA_R = np.pi / 6
    MU = 0.0

    # Plot data
    N_POINTS = 1000
    N_CONTOURS = 10
    X_PLOT_MIN = 3e-2
    X_PLOT_MAX = 0.20
    Y_PLOT_MIN = 3e-2
    Y_PLOT_MAX = 0.20

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

        theta_cr_max = atan2(2 * txy, txx - tyy) / 2

        if -pi / 2 <= (aux := theta_cr_max + pi / 2) <= pi / 2:
            theta_cr_min = aux
        else:
            theta_cr_min = theta_cr_max - pi / 2

        if (theta_cr_max <= -self.THETA_R and theta_cr_min <= -self.THETA_R) or (
                theta_cr_max >= self.THETA_R and theta_cr_min >= self.THETA_R):
            theta_1 = -self.THETA_R
            theta_2 = self.THETA_R
        else:
            if theta_cr_max < -self.THETA_R:
                theta_1 = -self.THETA_R
            elif theta_cr_max > self.THETA_R:
                theta_1 = self.THETA_R
            else:
                theta_1 = theta_cr_max

            if theta_cr_min < -self.THETA_R:
                theta_2 = -self.THETA_R
            elif theta_cr_min > self.THETA_R:
                theta_2 = self.THETA_R
            else:
                theta_2 = theta_cr_min

        return theta_1, theta_2

    def c_ef(self, x1, x2):
        theta_1, theta_2 = self.thetas_lim(x1, x2)
        c1 = self.c_theta(x1, x2, theta_1)
        c2 = self.c_theta(x1, x2, theta_2)

        return (c1 + c2 + sqrt((c1 - c2) ** 2 + self.mu(x1, x2) ** 2)) / 2

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
                z_tmp = self.c_ef(x_mesh[i, j], y_mesh[i, j])
                if self.volume_constraint(x_mesh[i, j], y_mesh[i, j]) < 0:
                    z_mesh[i, j] = z_tmp
                    if z_tmp < z_min:
                        z_min = z_tmp
                        x1_z_min = x_mesh[i, j]
                        x2_z_min = y_mesh[i, j]
                else:
                    z_mesh[i, j] = np.nan

        ax.contour(x_mesh, y_mesh, z_mesh, self.N_CONTOURS, linewidths=0.4, linestyles='solid', colors='k')
        cont = ax.contourf(x_mesh, y_mesh, z_mesh, self.N_CONTOURS, cmap='jet')
        ax.scatter(x1_z_min, x2_z_min, marker='o', color='orange', s=40, edgecolors='k', linewidths=0.5,
                   label=f'Cmin: {np.nanmin(z_mesh):.2f}')

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


class Cross(Example):
    # Design data
    L1 = 2
    L2 = 2
    E = 1
    F1 = 1
    F2 = 1

    # Optimization data
    V = 1
    BETA = 0.00
    THETA_R = np.pi / 6
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
    BETA = 0.5
    THETA_R = np.pi / 15
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
# print(ex.c_ef(0.125, 0.125))
ex.plot_contour()

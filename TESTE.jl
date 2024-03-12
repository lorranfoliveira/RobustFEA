using Plots

# Função para gerar uma reta aleatória
function gerar_reta()
    # Gerando coeficientes aleatórios
    a = rand() * 10
    b = rand() * 10

    # Gerando pontos para a reta
    x = linspace(0, 10, 100)
    y = a * x + b

    return (x, y)
end

# Gerando 5 retas aleatórias
retas = [gerar_reta() for i in 1:5]

# Gerando cores e espessuras aleatórias
cores = rand(RGB, 5)
espessuras = rand(5, 10)

# Plotando as retas
plot(retas[1][1], retas[1][2], color=cores[1], linewidth=espessuras[1])
plot(retas[2][1], retas[2][2], color=cores[2], linewidth=espessuras[2])
plot(retas[3][1], retas[3][2], color=cores[3], linewidth=espessuras[3])
plot(retas[4][1], retas[4][2], color=cores[4], linewidth=espessuras[4])
plot(retas[5][1], retas[5][2], color=cores[5], linewidth=espessuras[5])

# Criando um colorbar
colorbar(espessuras, legend=false)

# Ajustando o título e os rótulos dos eixos
title("Gráfico com várias retas independentes")
xlabel("x")
ylabel("y")

# Mostrando o gráfico
show()
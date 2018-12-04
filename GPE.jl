#input parameters--------------------------
delt_t = -(10^-3)*im

delt_x = 10^-3
x_end = 1
#N_x = Int(floor(2*x_end/delt_x)) # calculated value (default)
N_x = (10^3) #manual value
x_array = LinRange(-x_end,x_end,N_x)

k = 1
m = 1
g = 5*10^5
N = 10^3
#---------------------------------------------------


#write the guess wavefunction here
function psi_guess(x)
    return pi
end


#-----------------------------------------------------------

#core Functions for the algortihm___________________________________
function psi_guess_array()
    psi_guess_array = Float64[]

    for x in x_array
        push!(psi_guess_array,psi_guess(x))
    end
    return normalize(psi_guess_array)
end

function pot(x, psi)
    pot = ((k/2)*(x^2)+g*(conj(psi)*psi))
    return pot
end


function e_V(x, psi)
    return exp.(-pot(x, psi)*(delt_t)*im)
end

function e_T(n)
    p = ((2*pi)*n)/N_x
    return exp(-((p^2)/2m)*(delt_t/2)*im)
end

function time_step_T(array)
    psi_k_T = ComplexF64[]

    for n = 1:N_x
        k_T = array[n]*e_T(n)
        push!(psi_k_T, k_T)
    end

    return psi_k_T
end

function time_step_V(array)
    return_array = ComplexF64[]
    for x = 1:N_x
        k_V = array[x]*e_V(x_array[x], array[x])
        push!(return_array, k_V)
    end
    return return_array
end


#evolves psi(x_i) value from t_start to t_end
using FFTW
# using FFTViews
function time_evolve_step(array)
    psi_k_1 = fftshift(fft(array))
    psi_k_T_1 = time_step_T(psi_k_1)
    psi_x_T_1 = ifft(psi_k_T_1)
    psi_x_V = time_step_V(psi_x_T_1)
    psi_k = fftshift(fft(psi_x_V))
    psi_k_T = time_step_T(psi_k)
    psi_x_T = ifft(psi_k_T)
    return normalize(psi_x_T)
end


function time_evolve(array, t)
    evolved_array = reduce((x, y) -> time_evolve_step(x), 1:t, init=array)
    return normalize(evolved_array)
end

function normalize(array)
    a = array .* conj.(array)
    s = sqrt(sum(a))
    return (array/s)*sqrt(N)
end
##################################

#Plotters____________________________________________________
using Plots
#plots guess psi
psi = psi_guess_array()
time_step = time_evolve_step(psi)
t = time_evolve(psi, 10000)
t_2 = conj.(t) .* t

#plot(x_array, psi_guess_array(), title = "Guess Psi")
#plot(x_array, time_step, title = "Time step")

plot(x_array, real(t_2), title = "Psi Evolved")


# anim = @animate for i=1:800
#     t = time_evolve(psi, i)
#     plot(x_array, real(conj.(t) .* t), title = "Psi Evolved")
# end
# gif(anim, "C:/Users/Alucard/Desktop/julia/gifs/SE_e^-x_fps10.gif", fps = 10)

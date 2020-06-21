memoizer = Dict()
function dynsolver(damages, probs,
                threshold::Real, n::Int64)
    ### We want to maximize the probability of hitting some damage threshold in n shots
    ### This solver is used when you can update your policy after every shot
    ### Returns (score, action,)

    ## boundary conditions
    if threshold <= 0
        return 1
    elseif n == 0
        return 0
    end

    ## Check to see if this has already been calculated
    global memoizer
    if haskey(memoizer,(threshold, n,))
        return memoizer[(threshold,n,)]
    end

    ## Otherwise, let's calculate it
    best_score = 0
    best_action = 0
    for a in range(1, stop=length(damages))
        score = probs[a]*dynsolver(damages, probs, threshold-damages[a], n-1)[1] + (1-probs[a])*dynsolver(damages, probs, threshold, n-1)[1]
        if score >= best_score
            best_score = score
            best_action = a
        end
    end

    ## Memoize our result
    memoizer[(threshold, n,)] = (best_score, best_action,)

    ## And return
    (best_score, best_action,)
end

function dynsolver_start(damages, probs,
                threshold::Real, n::Int64)
    # Resetting the memoizer
    global memoizer
    memoizer = Dict()

    # Actually running the code
    return dynsolver(damages, probs, threshold, n)
end

function static_solver(damages, probs, threshold::Real, n::Int64, damprobs=Dict(0=>1))
    ### What if you had to decide on the spot how many shots to take at which areas? And you can't reconsider
    ### This solver is more complex and works on cumulative probailities of certain damages at certain points.
    ### Could be made much more efficient by rewriting as a dynamic program

    ## Boundary condition
    if n <= 0
        return (get(damprobs, threshold, 0), tuple())
    end

    ## Rest of the calculation
    best_action = 0
    best_score = -1
    for a in range(1, stop=length(damages))
        # Calculating the new probability distribution
        new_damprobs = Dict()
        for cur_damage in keys(damprobs)
            new_damprobs[min(threshold, damages[a]+cur_damage)] = get(new_damprobs,min(threshold, damages[a]+cur_damage), 0) + damprobs[cur_damage]*probs[a]
            new_damprobs[cur_damage] = get(new_damprobs,cur_damage,0) + damprobs[cur_damage] * (1-probs[a])
        end

        temp_score, temp_action = static_solver(damages, probs, threshold, n-1, new_damprobs)
        if temp_score >= best_score
            best_score = temp_score
            best_action = (a, temp_action...)
        end
    end

    return best_score, best_action
end

function getWavefunctionRG(initState::Dict{BitVector,Float64}, alphaValues::Vector{Float64}, numSteps::Integer, unitaryOperatorFunction::Function, stateExpansionFunction::Function, sectors::String; maxSize::Int64=0)

    @assert numSteps ≤ length(alphaValues)
    numEntangled = div(length(collect(keys(initState))[1]), 2)
    stateFlowArray = Dict{BitVector,Float64}[]
    push!(stateFlowArray, initState)

    for alpha in alphaValues[1:numSteps]
        newState = stateExpansionFunction(stateFlowArray[end], sectors)
        unitaryOperatorList = unitaryOperatorFunction(alpha, numEntangled, sectors)
        numEntangled = div(length(collect(keys(newState))[1]), 2)
        mergewith!(+, newState, fetch.([Threads.@spawn ApplyOperator([operator], newState) for operator in unitaryOperatorList])...)


        if maxSize < length(newState)
            newState = Dict(sort(collect(newState), by=x->x|>last|>abs)[1:maxSize])
            println("Drop ratio ~ ", round(sum(sort(collect(values(newState)))[maxSize:end] .^ 2) / sum(values(newState) .^ 2), sigdigits=1))
        end
        total_norm = sum(values(newState) .^ 2)^0.5
        newState = Dict(keys(newState) .=> values(newState) ./ total_norm)
        push!(stateFlowArray, newState)
    end

    return stateFlowArray
end

const TaskIdType = UInt64

const NoTask = TaskIdType(0)
taskid(id::TaskIdType) = id
taskid(th::Thunk) = TaskIdType(th.id)
taskid(ch::Chunk) = TaskIdType(hash(collect(ch)))
taskid(executable) = TaskIdType(hash(executable))

function tasklog(env, msg...)
    env.debug && info(env.name, " : ", env.id, " : ", msg...)
end

function taskexception(env, ex, bt)
    xret = CapturedException(ex, bt)
    tasklog(env, "exception $xret")
    @show xret
    xret
end

function collect_chunks(dag)
    if isa(dag, Chunk)
        return collect(dag)
    elseif isa(dag, Thunk)
       dag.inputs = map(collect_chunks, dag.inputs)
       return dag
    else
       return dag
    end
end

function get_drefs(dag, bucket::Vector{Chunk}=Vector{Chunk}())
   if isa(dag, Chunk)
       if isa(dag.handle, DRef)
           push!(bucket, dag)
       end
   elseif isa(dag, Thunk)
       map(x->get_drefs(x, bucket), dag.inputs)
   end
   bucket
end

#=
get_frefs(dag) = map(chunktodisk, get_drefs(dag))
=#

chunktodisk(chunk) = Chunk(chunk.chunktype, chunk.domain, movetodisk(chunk.handle), true)

function dref_to_fref(dag)
    if isa(dag, Thunk)
        dag.inputs = map(x->(isa(x,Chunk) && isa(x.handle, DRef)) ? chunktodisk(x) : x, dag.inputs)
        map(x->dref_to_fref(x), dag.inputs)
    end
    dag
end

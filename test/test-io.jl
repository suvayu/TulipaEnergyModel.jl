@testset "Input validation" begin
    @testset "Make sure that input validation fails for bad files" begin
        dir = joinpath(INPUT_FOLDER, "Tiny")
        @test_throws ArgumentError TulipaEnergyModel.read_csv_with_schema(
            joinpath(dir, "bad-assets-data.csv"),
            TulipaEnergyModel.AssetData,
        )
    end
end

@testset "Graph structure" begin
    @testset "Graph structure is correct" begin
        dir = joinpath(INPUT_FOLDER, "Tiny")
        graph =
            create_graph(joinpath(dir, "assets-data.csv"), joinpath(dir, "flows-data.csv"))

        @test Graphs.nv(graph) == 6
        @test Graphs.ne(graph) == 5
        @test collect(Graphs.edges(graph)) ==
              [Graphs.Edge(e) for e in [(1, 6), (2, 6), (3, 6), (4, 6), (5, 6)]]
    end
end

@testset "Test parsing of time intervals" begin
    @testset "compute_time_intervals manages all cases" begin
        time_steps_per_rp = Dict(1 => 1:12, 2 => 1:24)
        df = DataFrame(
            :id => [1, 2, 2, 3],
            :rep_period_id => [1, 1, 2, 2],
            :specification => [:uniform, :explicit, :math, :math],
            :time_intervals => ["3", "4;4;4", "3x4+4x3", "2x2+2x3+2x4+1x6"],
        )
        elements = [1, 2, 3] # Doesn't matter if it is assets or flows for test
        time_intervals = compute_time_intervals(df, elements, time_steps_per_rp)
        expected = Dict(
            (1, 1) => [1:3, 4:6, 7:9, 10:12],
            (2, 1) => [1:4, 5:8, 9:12],
            (3, 1) => [i:i for i = 1:12],
            (1, 2) => [i:i for i = 1:24],
            (2, 2) => [1:4, 5:8, 9:12, 13:15, 16:18, 19:21, 22:24],
            (3, 2) => [1:2, 3:4, 5:7, 8:10, 11:14, 15:18, 19:24],
        )
        for id = 1:3, rp = 1:2
            @test time_intervals[(id, rp)] == expected[(id, rp)]
        end
    end

    @testset "If the math doesn't match, raise exception" begin
        TEM = TulipaEnergyModel
        @test_throws AssertionError TEM._parse_time_intervals(Val(:uniform), "3", 1:13)
        @test_throws AssertionError TEM._parse_time_intervals(Val(:uniform), "3", 1:14)
        @test_throws AssertionError TEM._parse_time_intervals(
            Val(:explicit),
            "3;3;3;3",
            1:11,
        )
        @test_throws AssertionError TEM._parse_time_intervals(
            Val(:explicit),
            "3;3;3;3",
            1:13,
        )
        @test_throws AssertionError TEM._parse_time_intervals(
            Val(:explicit),
            "3;3;3;3",
            1:14,
        )
        @test_throws AssertionError TEM._parse_time_intervals(Val(:math), "3x4", 1:11)
        @test_throws AssertionError TEM._parse_time_intervals(Val(:math), "3x4", 1:13)
        @test_throws AssertionError TEM._parse_time_intervals(Val(:math), "3x4", 1:14)
    end
end
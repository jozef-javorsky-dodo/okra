const std = @import("std");

pub fn NodeList(comptime K: u8, comptime Q: u32) type {
    const Node = @import("Node.zig").Node(K, Q);

    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        nodes: std.ArrayListUnmanaged(Node),

        pub fn init(allocator: std.mem.Allocator) Self {
            const nodes = std.ArrayListUnmanaged(Node){};
            return Self{ .allocator = allocator, .nodes = nodes };
        }

        pub fn deinit(self: *Self) void {
            for (self.nodes.items) |node| {
                self.allocator.free(node.hash);
                if (node.key) |key|
                    self.allocator.free(key);
                if (node.value) |value|
                    self.allocator.free(value);
            }

            self.nodes.deinit(self.allocator);
        }

        pub fn clear(self: *Self) void {
            for (self.nodes.items) |node| {
                self.allocator.free(node.hash);
                if (node.key) |key|
                    self.allocator.free(key);
                if (node.value) |value|
                    self.allocator.free(value);
            }

            self.nodes.clearRetainingCapacity();
        }

        pub fn append(self: *Self, node: Node) !void {
            try self.nodes.append(self.allocator, .{
                .level = node.level,
                .key = try self.createKey(node.key),
                .hash = try self.createHash(node.hash),
                .value = try self.createKey(node.value),
            });
        }

        fn createKey(self: Self, key: ?[]const u8) !?[]const u8 {
            if (key) |bytes| {
                const result = try self.allocator.alloc(u8, bytes.len);
                @memcpy(result, bytes);
                return result;
            } else {
                return null;
            }
        }

        fn createHash(self: Self, hash: *const [K]u8) !*const [K]u8 {
            const result = try self.allocator.alloc(u8, K);
            @memcpy(result, hash);
            return result[0..K];
        }
    };
}

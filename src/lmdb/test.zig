const std = @import("std");
const expectEqual = std.testing.expectEqual;
const resolve = std.fs.path.resolve;

const Environment = @import("./environment.zig").Environment;
const Transaction = @import("./transaction.zig").Transaction;
const Cursor = @import("./cursor.zig").Cursor;

const compareEntries = @import("./compare.zig").compareEntries;

const allocator = std.heap.c_allocator;

test "compareEntries" {
  const K: comptime_int = 1;
  const V: comptime_int = 3;

  var buffer: [4096]u8 = undefined;
  var tmp = std.testing.tmpDir(.{});
  var tmpPath = try tmp.dir.realpath(".", &buffer);

  var pathA = try resolve(allocator, &[_][]const u8{ tmpPath, "a.mdb" });
  defer allocator.free(pathA);
  var pathB = try resolve(allocator, &[_][]const u8{ tmpPath, "b.mdb" });
  defer allocator.free(pathB);

  var envA = try Environment(K, V).open(pathA, .{});
  var txnA = try Transaction(K, V).open(envA, false);
  var dbiA = try txnA.openDbi();

  try txnA.set(dbiA, "x", "foo");
  try txnA.set(dbiA, "y", "bar");
  try txnA.set(dbiA, "z", "baz");
  try txnA.commit();

  var envB = try Environment(K, V).open(pathB, .{});
  var txnB = try Transaction(K, V).open(envB, false);
  var dbiB = try txnB.openDbi();
  try txnB.set(dbiB, "y", "bar");
  try txnB.set(dbiB, "z", "qux");
  try txnB.commit();

  try expectEqual(try compareEntries(K, V, pathA, pathB, .{}), 2);
  try expectEqual(try compareEntries(K, V, pathB, pathA, .{}), 2);

  txnB = try Transaction(K, V).open(envB, false);
  try txnB.set(dbiB, "x", "foo");
  try txnB.set(dbiB, "z", "baz");
  try txnB.commit();

  try expectEqual(try compareEntries(K, V, pathA, pathB, .{}), 0);
  try expectEqual(try compareEntries(K, V, pathB, pathA, .{}), 0);

  envA.close();
  envB.close();

  tmp.cleanup();
}
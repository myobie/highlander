defmodule Highlander.Registry.ZK.Helpers do
  @base_path "/__shared_objects__"

  def path({ type, id }) when is_atom(type) do
    "#{@base_path}/#{type}/#{id}/"
  end

  def path({ type, _id} = name, << _ :: size(256), "-", _ :: binary >> = node_name) when is_atom(type) do
    "#{path(name)}/#{node_name}"
  end

  def prefix({ type, _id} = name, << uuid :: size(256) >>) when is_atom(type) do
    "#{path(name)}/#{uuid}-"
  end

  def sequence(<< _ :: size(256), "-", seq :: binary >>) do
    String.to_integer seq
  end

  def sort(children) do
    Enum.sort_by children, &sequence/1
  end

  def first(children) do
    children
    |> List.first
  end
end

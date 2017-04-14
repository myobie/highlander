defmodule Highlander.Registry.ZK.Helpers do
  @base_path "/__shared_objects__"

  def path({ type, id }) when is_atom(type) do
    "#{@base_path}/#{type}/#{id}"
  end

  def prefix({ type, _id} = name, << _ :: size(256) >> = uuid) when is_atom(type) do
    "#{path(name)}/#{uuid}-"
  end

  def path({ type, _id} = name, << _ :: size(256), 45, _ :: size(80) >> = znode_name) when is_atom(type) do
    "#{path(name)}/#{znode_name}"
  end

  def sequence(<< _ :: size(256), 45, seq :: size(80) >>) do
    seq
    |> to_string
    |> String.to_integer
  end

  def sort(children) do
    Enum.sort_by children, &sequence/1
  end

  def first(children) do
    children |> List.first
  end
end

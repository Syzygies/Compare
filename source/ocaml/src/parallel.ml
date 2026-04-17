let swap arr i j =
  let temp = arr.(i) in
  arr.(i) <- arr.(j);
  arr.(j) <- temp

let map cores init run tasks =
  let tasks = Array.of_list tasks in
  let count = Array.length tasks in

  let next = Atomic.make 0 in
  let order = Array.init count (fun i -> i) in

  let results = Array.make count init in

  let shuffle arr =
    for i = count - 1 downto 1 do
      let j = Random.int (i + 1) in
      swap arr i j
    done
  in
  shuffle order;

  let worker () =
    let rec loop () =
      let index = Atomic.fetch_and_add next 1 in
      if index < count then
        ( let index = order.(index) in
          results.(index) <- run tasks.(index);
          loop () )
    in
    loop ()
  in

  let domains =
    Array.init (cores - 1) (fun _ -> Domain.spawn worker)
  in

  worker ();
  Array.iter Domain.join domains;
  Array.to_list results

package com.linx.cmdb.repository;

import com.linx.cmdb.entity.Command;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommandRepository extends JpaRepository<Command, Long> {
    List<Command> findByLabelContainingIgnoreCase(String label);
}
